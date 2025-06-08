use crate::graphic::Graphic;
mod surface;
use wayland_client::Proxy;
use wayland_client::{
    Connection, Dispatch, EventQueue, QueueHandle,
    protocol::{
        wl_buffer,
        wl_compositor::{self, WlCompositor},
        wl_output::{self, WlOutput},
        wl_registry, wl_shm_pool, wl_surface,
    },
};
use wayland_client::backend::ObjectId;

use wayland_protocols_wlr::layer_shell::v1::client::{
    zwlr_layer_shell_v1::{self, ZwlrLayerShellV1},
    zwlr_layer_surface_v1::{self, ZwlrLayerSurfaceV1},
};

pub struct State<G: Graphic> {
    layer_shell: Option<ZwlrLayerShellV1>,
    compositor: Option<WlCompositor>,
    surfaces: std::collections::HashMap<ObjectId, surface::Surface<G>>,
    unused_outputs: std::collections::HashSet<wl_output::WlOutput>,
    output_sizes: std::collections::HashMap<ObjectId, (i32, i32)>,
    display_ptr: *mut std::ffi::c_void,
}

impl<G> State<G>
where
    G: Graphic,
{
    fn new(connection: &Connection) -> Self {
        let display = connection.display();
        let display_ptr = display.backend().upgrade().unwrap().display_ptr();
        let mut event_queue: EventQueue<State<G>> = connection.new_event_queue();
        let qhandle = event_queue.handle();
        let _registry = display.get_registry(&qhandle, ());
        let mut state = State {
            layer_shell: None,
            compositor: None,
            surfaces: std::collections::HashMap::new(),
            unused_outputs: std::collections::HashSet::new(),
            output_sizes: std::collections::HashMap::new(),
            display_ptr: display_ptr as *mut std::ffi::c_void,
        };
        event_queue
            .roundtrip(&mut state)
            .expect("Failed to initialize Wayland state");
        if state.layer_shell.is_none() {
            eprintln!("Layer shell not available");
        }
        if state.compositor.is_none() {
            eprintln!("Compositor not available");
        }
        state
    }

    fn try_create_surfaces(
        &mut self,
        qhandle: &QueueHandle<State<G>>,
    ) -> anyhow::Result<()> {
        if let (
            Some(layer_shell), Some(compositor)) 
            = (&self.layer_shell, &self.compositor
        ) {
            let mut removal_list = vec![];
            for output in self.unused_outputs.iter() {
                if let Some((w, h)) = self.output_sizes.get(&output.id()).cloned() {
                    let surface = surface::Surface::<G>::new(
                        output,
                        layer_shell,
                        compositor,
                        qhandle,
                        w,
                        h,
                        self.display_ptr,
                    )?;
                    let id = output.id();
                    self.surfaces.insert(id, surface);
                    removal_list.push(output.clone());
                }
            }
            for output in removal_list {
                self.unused_outputs.remove(&output);
            }
        }
        Ok(())
    }
}

impl<G> Dispatch<wl_registry::WlRegistry, ()> 
for State<G>
where
    G: Graphic,
{
    fn event(
        state: &mut Self,
        registry: &wl_registry::WlRegistry,
        event: wl_registry::Event,
        _data: &(),
        _conn: &Connection,
        qh: &QueueHandle<State<G>>,
    ) {
        match event {
            wl_registry::Event::Global {
                name,
                interface,
                version,
            } => {
                if interface == ZwlrLayerShellV1::interface().name {
                    let layer_shell =
                        registry.bind::<ZwlrLayerShellV1, _, _>(name, version, qh, ());
                    state.layer_shell = Some(layer_shell);
                }
                if interface == WlCompositor::interface().name {
                    let compositor = registry.bind::<WlCompositor, _, _>(name, version, qh, ());
                    state.compositor = Some(compositor);
                }
                if interface == wl_output::WlOutput::interface().name {
                    let output = registry.bind::<wl_output::WlOutput, _, _>(name, version, qh, ());
                    state.unused_outputs.insert(output);
                }
            }
            _ => {}
        }
    }
}

impl<G> Dispatch<ZwlrLayerShellV1, ()>
for State<G>
where
    G: Graphic,
{
    fn event(
        state: &mut Self,
        _layer_shell: &ZwlrLayerShellV1,
        _event: zwlr_layer_shell_v1::Event,
        _data: &(),
        _conn: &Connection,
        _qh: &QueueHandle<State<G>>,
    ) {
    }
}

impl<G> Dispatch<WlCompositor, ()> 
for State<G>
where
    G: Graphic,
{
    fn event(
        state: &mut Self,
        _compositor: &WlCompositor,
        _event: wl_compositor::Event,
        _data: &(),
        _conn: &Connection,
        _qh: &QueueHandle<State<G>>,
    ) {
    }
}

impl<G> Dispatch<wl_output::WlOutput, ()>
for State<G>
where
    G: Graphic,
{
    fn event(
        state: &mut Self,
        output: &WlOutput,
        event: wl_output::Event,
        _data: &(),
        _conn: &Connection,
        qh: &QueueHandle<State<G>>,
    ) {
        match event {
            wl_output::Event::Geometry {
                x,
                y,
                ..
            } => {
                // Store the geometry of the output
                let id = output.id();
                state.output_sizes.insert(id.clone(), (x, y));
                if let Some(surface) = state.surfaces.get_mut(&id) {
                    surface.resize(x, y)
                        .expect("Failed to resize surface");
                }
                else {
                    state.unused_outputs.insert(output.clone());
                    if let Err(e) = state.try_create_surfaces(qh) {
                        eprintln!("Failed to create surfaces: {}", e);
                    }
                }
            }
            wl_output::Event::Done => {
                let id = output.id();
                if let Some(surface) = state.surfaces.get_mut(&id) {
                    surface.draw().expect("Failed to draw surface");
                }
            }
            _ => {}
        }
    }
}

impl<G> Dispatch<wl_surface::WlSurface, ()>
for State<G>
where
    G: Graphic,
{
    fn event(
        state: &mut Self,
        _surface: &wl_surface::WlSurface,
        _event: wl_surface::Event,
        _data: &(),
        _conn: &Connection,
        _qh: &QueueHandle<State<G>>,
    ) {
        // Handle surface events if needed
    }
}

impl<G> Dispatch<ZwlrLayerSurfaceV1, ()>
for State<G>
where
    G: Graphic,
{
    fn event(
        state: &mut Self,
        _layer_surface: &ZwlrLayerSurfaceV1,
        _event: zwlr_layer_surface_v1::Event,
        _data: &(),
        _conn: &Connection,
        _qh: &QueueHandle<State<G>>,
    ) {
        // Handle layer surface events if needed
    }
}
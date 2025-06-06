use std::io::Write;
use std::os::unix::io::AsFd;
use wayland_client::{
    Connection, Dispatch, EventQueue, QueueHandle,
    protocol::{wl_buffer, wl_compositor, wl_registry, wl_shm, wl_shm_pool, wl_surface},
};
use wayland_protocols_wlr::layer_shell::v1::client::{
    zwlr_layer_shell_v1::{self, ZwlrLayerShellV1},
    zwlr_layer_surface_v1::{self, ZwlrLayerSurfaceV1},
};
use wayland_client::Proxy;

#[derive(Clone)]
struct State {
    layer_shell: Option<ZwlrLayerShellV1>,
    compositor: Option<wl_compositor::WlCompositor>,
}

impl Dispatch<wl_registry::WlRegistry, (), State> for State {
    fn event(
        state: &mut Self,
        registry: &wl_registry::WlRegistry,
        event: wl_registry::Event,
        _data: &(),
        _connection: &Connection,
        qhandle: &QueueHandle<State>,
    ) {
        match event {
            wl_registry::Event::Global { name, interface, version } => {
                if interface == ZwlrLayerShellV1::interface().name {
                    eprintln!(
                        "Found layer shell interface: {} (version {})",
                        interface, version
                    );
                    let layer_shell = registry
                        .bind::<ZwlrLayerShellV1, _, _>
                        (name, version, qhandle, ());
                    state.layer_shell = Some(layer_shell);
                }
                else if interface == wl_compositor::WlCompositor::interface().name {
                    eprintln!(
                        "Found compositor interface: {} (version {})",
                        interface, version
                    );
                    let compositor = registry
                        .bind::<wl_compositor::WlCompositor, _, _>
                        (name, version, qhandle, ());
                    state.compositor = Some(compositor);
                }
            }
            wl_registry::Event::GlobalRemove { name } => {
                if let Some(ref mut layer_shell) = state.layer_shell {
                    if layer_shell.id().protocol_id() == name {
                        layer_shell.destroy();
                        state.layer_shell = None;
                    }
                }
            }
            _ => {}
        }
    }
}

impl Dispatch<ZwlrLayerShellV1, ()> for State {
    fn event(
        _state: &mut Self,
        _proxy: &ZwlrLayerShellV1,
        _event: <ZwlrLayerShellV1 as Proxy>::Event,
        _data: &(),
        _conn: &Connection,
        _qhandle: &QueueHandle<Self>,
    ) {
    }
}

impl Dispatch<wl_compositor::WlCompositor, ()> for State {
    fn event(
        _state: &mut Self,
        _proxy: &wl_compositor::WlCompositor,
        _event: <wl_compositor::WlCompositor as Proxy>::Event,
        _data: &(),
        _conn: &Connection,
        _qhandle: &QueueHandle<Self>,
    ) {
    }
}

impl Dispatch<wl_surface::WlSurface, ()> for State {
    fn event(
        _state: &mut Self,
        _proxy: &wl_surface::WlSurface,
        _event: <wl_surface::WlSurface as Proxy>::Event,
        _data: &(),
        _conn: &Connection,
        _qhandle: &QueueHandle<Self>,
    ) {
    }
}

impl Dispatch<zwlr_layer_surface_v1::ZwlrLayerSurfaceV1, ()> for State {
    fn event(
        _state: &mut Self,
        _proxy: &zwlr_layer_surface_v1::ZwlrLayerSurfaceV1,
        _event: <zwlr_layer_surface_v1::ZwlrLayerSurfaceV1 as Proxy>::Event,
        _data: &(),
        _conn: &Connection,
        _qhandle: &QueueHandle<Self>,
    ) {
    }
}

fn main() {
    let connection = Connection::connect_to_env().expect("Failed to connect to Wayland server");
    let _display = connection.display();
    let mut event_queue: EventQueue<State> = connection.new_event_queue();
    let qhandle = event_queue.handle();
    // let registry = display.get_registry(&qhandle, ());
    let mut state = State { layer_shell: None, compositor: None };
    event_queue
        .roundtrip(&mut state)
        .expect("Failed to process initial registry events");
    let layer_shell = state.layer_shell
        .clone()
        .expect("Layer shell not available on this Wayland server");
    let compositor = state.compositor
        .clone()
        .expect("Compositor not available on this Wayland server");
    let surface = compositor.create_surface(&qhandle, ());
    let layer = zwlr_layer_shell_v1::Layer::Top;
    let namespace = "background_layer".to_string();
    let layer_surface = layer_shell.get_layer_surface(&surface, None, layer, namespace , &qhandle, ());
    layer_surface.set_anchor(
        zwlr_layer_surface_v1::Anchor::Top
        | zwlr_layer_surface_v1::Anchor::Left
        | zwlr_layer_surface_v1::Anchor::Right
        | zwlr_layer_surface_v1::Anchor::Bottom,
    );
    layer_surface.set_exclusive_zone(0);
    layer_surface.set_size(1920, 1080);
    let keyboard_interactivity = zwlr_layer_surface_v1::KeyboardInteractivity::None;
    layer_surface.set_keyboard_interactivity(keyboard_interactivity);
    surface.commit();
    loop {
        event_queue
            .blocking_dispatch(&mut state)
            .expect("Failed to dispatch Wayland events");
    }
}
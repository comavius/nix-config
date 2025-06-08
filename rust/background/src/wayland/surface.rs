use wayland_client::{
    Proxy,
    Connection, Dispatch, EventQueue, QueueHandle,
    backend::ObjectId
};
use wayland_client::protocol::{
    wl_buffer::WlBuffer,
    wl_compositor::WlCompositor,
    wl_output::WlOutput,
    wl_surface::WlSurface,
};
use wayland_protocols_wlr::layer_shell::v1::client::{
    zwlr_layer_shell_v1::{
        ZwlrLayerShellV1,
        Layer,
    },
    zwlr_layer_surface_v1::{
        ZwlrLayerSurfaceV1,
        Anchor,
        KeyboardInteractivity,
    },
};
use crate::graphic::Graphic;
use crate::wayland::State;

use wayland_egl::WlEglSurface;

pub struct Surface<G>
where
    G: Graphic,
{
    surface: WlSurface,
    layer_surface: ZwlrLayerSurfaceV1,
    egl_surface: WlEglSurface,
    graphic: G,
}

impl<G> Surface<G>
where
    G: Graphic,
{
    pub fn new(
        output: &WlOutput,
        layer_shell: &ZwlrLayerShellV1,
        compositor: &WlCompositor,
        qh: &wayland_client::QueueHandle<State<G>>,
        width: i32,
        height: i32,
        display_ptr: *mut std::ffi::c_void,
    ) -> anyhow::Result<Self> {
        let surface = compositor.create_surface(qh, ());
        let layer_surface = layer_shell.get_layer_surface(
            &surface,
            Some(output),
            Layer::Background,
            "background".to_string(),
            qh,
            (),
        );
        layer_surface.set_size(width as u32, height as u32);
        layer_surface.set_anchor(
            Anchor::Top | Anchor::Bottom | Anchor::Left | Anchor::Right,
        );
        layer_surface.set_exclusive_zone(0);
        layer_surface.set_keyboard_interactivity(
            KeyboardInteractivity::None,
        );
        let egl_surface = WlEglSurface::new(surface.id().clone(), width, height)
            .map_err(|e| anyhow::anyhow!("Failed to create EGL surface: {}", e))?;
        let egl_surface_ptr = egl_surface.ptr() as *mut std::ffi::c_void;
        let graphic = G::new(egl_surface_ptr, display_ptr, width, height);
        Ok(Self {
            surface,
            layer_surface,
            egl_surface,
            graphic: graphic?,
        })
    }

    pub fn draw(&mut self) -> anyhow::Result<()> {
        self.graphic.draw()?;
        Ok(())
    }

    pub fn resize(&mut self, width: i32, height: i32) -> anyhow::Result<()> {
        self.layer_surface.set_size(width as u32, height as u32);
        self.egl_surface.resize(width, height, 0, 0);
        self.graphic.resize(width, height)?;
        Ok(())
    }
}

impl<G> Drop for Surface<G>
where
    G: Graphic,
{
    fn drop(&mut self) {
        self.layer_surface.destroy();
        self.surface.destroy();
    }
}
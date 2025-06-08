mod wayland;
mod graphic;
use std::io::Write;
use std::os::unix::io::AsFd;
use wayland_client::Proxy;
use wayland_client::{
    Connection, Dispatch, EventQueue, QueueHandle,
    protocol::{wl_buffer, wl_compositor, wl_registry, wl_shm, wl_shm_pool, wl_surface},
};
use wayland_protocols_wlr::layer_shell::v1::client::{
    zwlr_layer_shell_v1::{self, ZwlrLayerShellV1},
    zwlr_layer_surface_v1::{self, ZwlrLayerSurfaceV1},
};


fn main() {
    let connection = Connection::connect_to_env().expect("Failed to connect to Wayland server");
    let state = wayland::State::<graphic::graphic_impl::GraphicImpl>::new(&connection);
    state.start().expect("Failed to start Wayland event loop");
}

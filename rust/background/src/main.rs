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

#[derive(Clone)]
struct State {
    layer_shell: Option<ZwlrLayerShellV1>,
    compositor: Option<wl_compositor::WlCompositor>,
}

fn main() {
    let connection = Connection::connect_to_env().expect("Failed to connect to Wayland server");
    let display = connection.display();
    let mut event_queue: EventQueue<State> = connection.new_event_queue();
    let qhandle = event_queue.handle();
    let mut state = State {
        layer_shell: None,
        compositor: None,
    };
}

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

const WIDTH: i32 = 800;
const HEIGHT: i32 = 600;
// Add to your AppState
struct AppState {
    compositor: Option<wl_compositor::WlCompositor>,
    shm: Option<wl_shm::WlShm>,
    layer_shell: Option<ZwlrLayerShellV1>,
    surface: Option<wl_surface::WlSurface>,
    layer_surface: Option<ZwlrLayerSurfaceV1>,
    buffer: Option<wl_buffer::WlBuffer>,
}

impl Dispatch<wl_registry::WlRegistry, ()> for AppState {
    fn event(
        state: &mut Self,
        registry: &wl_registry::WlRegistry,
        event: wl_registry::Event,
        _data: &(),
        _conn: &Connection,
        qhandle: &QueueHandle<AppState>,
    ) {
        match event {
            wl_registry::Event::Global {
                name,
                interface,
                version,
            } => match interface.as_str() {
                "wl_compositor" => {
                    let compositor = registry.bind::<wl_compositor::WlCompositor, _, _>(
                        name,
                        version,
                        qhandle,
                        (),
                    );
                    state.compositor = Some(compositor);
                }
                "wl_shm" => {
                    let shm = registry.bind::<wl_shm::WlShm, _, _>(name, version, qhandle, ());
                    state.shm = Some(shm);
                }
                "zwlr_layer_shell_v1" => {
                    let layer_shell =
                        registry.bind::<ZwlrLayerShellV1, _, _>(name, version, qhandle, ());
                    state.layer_shell = Some(layer_shell);
                }
                _ => {}
            },
            _ => {}
        }
    }
}
use wayland_client::Proxy;

impl Dispatch<ZwlrLayerShellV1, ()> for AppState {
    fn event(
        _state: &mut Self,
        _proxy: &ZwlrLayerShellV1,
        _event: zwlr_layer_shell_v1::Event,
        _data: &(),
        _conn: &Connection,
        _qhandle: &QueueHandle<AppState>,
    ) {
        // Layer shell typically doesn't send events
    }
}

impl Dispatch<ZwlrLayerSurfaceV1, ()> for AppState {
    fn event(
        _state: &mut Self,
        layer_surface: &ZwlrLayerSurfaceV1,
        event: zwlr_layer_surface_v1::Event,
        _data: &(),
        _conn: &Connection,
        _qhandle: &QueueHandle<AppState>,
    ) {
        match event {
            zwlr_layer_surface_v1::Event::Configure {
                serial,
                width,
                height,
            } => {
                println!("Layer surface configure: {}x{}", width, height);
                layer_surface.ack_configure(serial);
                // Resize your buffer if needed
            }
            zwlr_layer_surface_v1::Event::Closed => {
                println!("Layer surface closed");
                // Handle surface being closed
            }
            _ => {}
        }
    }
}

impl Dispatch<wl_compositor::WlCompositor, ()> for AppState {
    fn event(
        _state: &mut Self,
        _compositor: &wl_compositor::WlCompositor,
        _event: wl_compositor::Event,
        _data: &(),
        _conn: &Connection,
        _qhandle: &QueueHandle<AppState>,
    ) {
    }
}

impl Dispatch<wl_surface::WlSurface, ()> for AppState {
    fn event(
        _state: &mut Self,
        _surface: &wl_surface::WlSurface,
        event: wl_surface::Event,
        _data: &(),
        _conn: &Connection,
        _qhandle: &QueueHandle<AppState>,
    ) {
        match event {
            wl_surface::Event::Enter { output } => {
                println!("Surface entered output: {:?}", output);
                // Handle surface entering an output (monitor)
                // You might want to adjust rendering parameters here
            }
            wl_surface::Event::Leave { output } => {
                println!("Surface left output: {:?}", output);
                // Handle surface leaving an output
            }
            wl_surface::Event::PreferredBufferScale { factor } => {
                println!("Preferred buffer scale: {}", factor);
                // Handle HiDPI scaling - adjust your buffer size accordingly
            }
            wl_surface::Event::PreferredBufferTransform { transform } => {
                println!("Preferred buffer transform: {:?}", transform);
                // Handle display rotation/transformation
            }
            _ => {}
        }
    }
}

impl Dispatch<wl_shm_pool::WlShmPool, ()> for AppState {
    fn event(
        _state: &mut Self,
        _pool: &wl_shm_pool::WlShmPool,
        _event: wl_shm_pool::Event,
        _data: &(),
        _conn: &Connection,
        _qh: &QueueHandle<AppState>,
    ) {
    }
}

impl Dispatch<wl_buffer::WlBuffer, ()> for AppState {
    fn event(
        _state: &mut Self,
        _buffer: &wl_buffer::WlBuffer,
        _event: wl_buffer::Event,
        _data: &(),
        _conn: &Connection,
        _qh: &QueueHandle<AppState>,
    ) {
    }
}

impl Dispatch<wl_shm::WlShm, ()> for AppState {
    fn event(
        state: &mut Self,
        _shm: &wl_shm::WlShm,
        event: wl_shm::Event,
        _data: &(),
        _conn: &Connection,
        qhandle: &QueueHandle<AppState>,
    ) {
        match event {
            wl_shm::Event::Format { format } => {
                println!("Supported format: {:?}", format);
                // You can check if ARGB8888 is supported here
            }
            _ => {}
        }
    }
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Step 1: Connect to Wayland
    let conn = Connection::connect_to_env()?;
    let display = conn.display();
    let mut event_queue = conn.new_event_queue();
    let qh = event_queue.handle();

    // Step 2: Get registry and bind to globals
    let _registry = display.get_registry(&qh, ());
    let mut app_state = AppState {
        compositor: None,
        shm: None,
        layer_shell: None,
        surface: None,
        layer_surface: None,
        buffer: None,
    };

    // Initial roundtrip to get globals
    event_queue.roundtrip(&mut app_state)?;

    // Step 3: Create surface
    let compositor = app_state.compositor.as_ref().unwrap();
    let surface = compositor.create_surface(&qh, ());
    let layer_shell = app_state.layer_shell.as_ref().unwrap();

    let layer_surface = layer_shell.get_layer_surface(
        &surface,
        None,                                // output - None means any output
        zwlr_layer_shell_v1::Layer::Overlay, // or Background, Bottom, Top
        "shader-viewer".to_string(),         // namespace
        &qh,
        (),
    );

    // Configure the layer surface
    layer_surface.set_size(WIDTH as u32, HEIGHT as u32);
    layer_surface.set_anchor(zwlr_layer_surface_v1::Anchor::empty()); // floating  
    layer_surface.set_exclusive_zone(0); // don't reserve space  
    // After creating the layer surface, add buffer creation  
    let shm = app_state.shm.as_ref().unwrap();  
    let mut file = tempfile::tempfile()?;  
    let stride = WIDTH * 4; // 4 bytes per pixel (ARGB)  
    let size = stride * HEIGHT;  
    
    // Fill with white pixels (0xFFFFFFFF in ARGB format)  
    let white_pixel = 0xFFFFFFFFu32;  
    for _ in 0..(WIDTH * HEIGHT) {  
        file.write_all(&white_pixel.to_ne_bytes())?;  
    }  
    file.flush()?;  
    
    let pool = shm.create_pool(file.as_fd(), size, &qh, ());  
    let buffer = pool.create_buffer(  
        0, WIDTH, HEIGHT, stride,   
        wl_shm::Format::Argb8888, &qh, ()  
    );  
    
    // Attach buffer to surface  
    surface.attach(Some(&buffer), 0, 0);  
    surface.commit();

    // Step 6: Keep the window alive
    loop {
        event_queue.blocking_dispatch(&mut app_state)?;
    }
}

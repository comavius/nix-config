use wayland_client::{
    Connection, Dispatch, EventQueue, QueueHandle,
    protocol::{wl_surface, wl_registry, wl_compositor},
};
use wayland_client::Proxy;

// Application state struct
struct AppState {
    // You can add your application-specific state here
    running: bool,
    compositor: Option<wl_compositor::WlCompositor>,
}

impl Dispatch<wl_compositor::WlCompositor, ()> for AppState {
    fn event(
        _state: &mut Self,
        _compositor: &wl_compositor::WlCompositor,
        _event: wl_compositor::Event,
        _data: &(),
        _conn: &Connection,
        _qhandle: &QueueHandle<AppState>,
    ) {}
}

// Implement Dispatch for the registry to handle global advertisements
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
            } => {
                if interface == wl_compositor::WlCompositor::interface().name {
                    let compositor = registry.bind::<wl_compositor::WlCompositor, _, _>(
                        name,
                        version,
                        qhandle,
                        (),
                    );
                    state.compositor = Some(compositor);
                }
            }
            wl_registry::Event::GlobalRemove { name: _name } => {}
            _ => {}
        }
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

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Step 1: Create connection to Wayland compositor
    let conn = Connection::connect_to_env()?;

    // Step 2: Get the display object (root Wayland object)
    let display = conn.display();

    // Step 3: Create event queue for processing events
    let mut event_queue = conn.new_event_queue();
    let qh = event_queue.handle();

    // Step 4: Create registry to discover available globals
    let _registry = display.get_registry(&qh, ());

    // Step 5: Initialize application state
    let mut app_state = AppState { running: true, compositor: None };

    // Step 6: Perform initial roundtrip to get all globals
    event_queue.roundtrip(&mut app_state)?;

    println!("Wayland client initialized successfully!");

    if let Some(ref compositor) = app_state.compositor {  
        println!("Creating surface...");  
        let surface = compositor.create_surface(&qh, ());  
        println!("Surface created successfully!");
    } else {  
        println!("No compositor found!");  
    }  
    Ok(())
}

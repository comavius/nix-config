pub mod graphic_impl;

pub trait Graphic: Sized + 'static {
    fn new(surface_ptr: *mut std::ffi::c_void, display_ptr: *mut std::ffi::c_void, width: i32, height: i32) -> anyhow::Result<Self>;
    fn draw(&mut self) -> anyhow::Result<()>;
    fn resize(&mut self, width: i32, height: i32) -> anyhow::Result<()>;
}

use std::{ffi::c_void, ptr};
use khronos_egl as egl;
use egl::{Instance, Display, Context, Surface};
use gl::types::*;

pub struct GraphicImpl {
    width: i32,
    height: i32,
    instance: Instance<egl::Static>,
    display: Display,
    context: Context,
    surface: Surface,
}

impl super::Graphic for GraphicImpl {
    fn new(surface_ptr: *mut c_void, display_ptr: *mut c_void, width: i32, height: i32) -> anyhow::Result<Self> {
        let instance = egl::Instance::new(egl::Static);
        let display = unsafe { instance.get_display(display_ptr) }
            .ok_or_else(|| anyhow::anyhow!("Failed to get EGL display"))?;
        assert!(display.as_ptr() != egl::NO_DISPLAY, "EGL display is not valid");
        instance.initialize(display)?;
        let attributes = [
            egl::SURFACE_TYPE,
            egl::WINDOW_BIT,
            egl::RENDERABLE_TYPE,
            egl::OPENGL_ES2_BIT,
            egl::RED_SIZE,
            8,
            egl::GREEN_SIZE,
            8,
            egl::BLUE_SIZE,
            8,
            egl::ALPHA_SIZE,
            8,
            egl::NONE,
        ];
        let config = instance.choose_first_config(display, &attributes)
            .expect("Failed to choose EGL config")
            .ok_or_else(|| anyhow::anyhow!("No suitable EGL config found"))?;
        let context_attribute = [
            egl::CONTEXT_MAJOR_VERSION, 4,
            egl::CONTEXT_MINOR_VERSION, 0,
            egl::CONTEXT_OPENGL_PROFILE_MASK, egl::CONTEXT_OPENGL_CORE_PROFILE_BIT,
            egl::NONE
        ];
        let context = instance.create_context(display, config, None, &context_attribute)
        .map_err(|e| anyhow::anyhow!("Failed to create EGL context: {}", e))?;
        let surface = unsafe {
            instance.create_window_surface(display, config, surface_ptr as *mut c_void, None)
                .map_err(|e| anyhow::anyhow!("Failed to create EGL surface: {}", e))?
        };
        instance.make_current(display, Some(surface), None, Some(context))
            .map_err(|e| anyhow::anyhow!("Failed to make EGL context current: {}", e))?;
        Ok(Self {
            width,
            height,
            instance,
            display,
            context,
            surface,
        })
    }

    fn draw(&mut self) -> anyhow::Result<()> {
        let v_shader_source = r#"
            #version 400
            in vec4 position;
            void main() {
                gl_Position = position;
            }
        "#;
        let f_shader_source = r#"
            #version 400
            out vec4 color;
            void main() {
                color = vec4(0.0, 0.5, 1.0, 1.0); // Blue background
            }
        "#;
        unsafe {
            let v_shader = gl::CreateShader(gl::VERTEX_SHADER);
            let c_str = std::ffi::CString::new(v_shader_source).unwrap();
            let ptr = c_str.as_ptr();
            gl::ShaderSource(v_shader, 1, &ptr, ptr::null());
            gl::CompileShader(v_shader);
            let f_shader = gl::CreateShader(gl::FRAGMENT_SHADER);
            let c_str = std::ffi::CString::new(f_shader_source).unwrap();
            let ptr = c_str.as_ptr();
            gl::ShaderSource(f_shader, 1, &ptr, ptr::null());
            gl::CompileShader(f_shader);
            let program = gl::CreateProgram();
            gl::AttachShader(program, v_shader);
            gl::AttachShader(program, f_shader);
            gl::LinkProgram(program);
            gl::UseProgram(program);
            let vertices: [GLfloat; 8] = [
                -1.0, -1.0, // Bottom left
                 1.0, -1.0, // Bottom right
                -1.0,  1.0, // Top left
                 1.0,  1.0, // Top right
            ];
            let mut vbo: GLuint = 0;
            gl::GenBuffers(1, &mut vbo);
            gl::BindBuffer(gl::ARRAY_BUFFER, vbo);
            gl::BufferData(gl::ARRAY_BUFFER, (vertices.len() * std::mem::size_of::<GLfloat>()) as GLsizeiptr, vertices.as_ptr() as *const _, gl::STATIC_DRAW);
            let position_location = gl::GetAttribLocation(program, std::ffi::CString::new("position").unwrap().as_ptr());
            gl::EnableVertexAttribArray(position_location as GLuint);
            gl::VertexAttribPointer(position_location as GLuint, 2, gl::FLOAT, gl::FALSE, 0, ptr::null());
            gl::ClearColor(0.0, 0.5, 1.0, 1.0); // Set clear color to blue
            gl::Clear(gl::COLOR_BUFFER_BIT);
            gl::DrawArrays(gl::TRIANGLE_STRIP, 0, 4);
            gl::DisableVertexAttribArray(position_location as GLuint);
            gl::DeleteShader(v_shader);
            gl::DeleteShader(f_shader);
            gl::DeleteProgram(program);
            self.instance.swap_buffers(self.display, self.surface)
                .map_err(|e| anyhow::anyhow!("Failed to swap buffers: {}", e))?;
        }
        Ok(())
    }

    fn resize(&mut self, width: i32, height: i32) -> anyhow::Result<()> {
        self.width = width;
        self.height = height;
        Ok(())
    }
}

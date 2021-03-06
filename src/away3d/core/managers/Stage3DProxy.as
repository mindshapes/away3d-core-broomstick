package away3d.core.managers
{
	import away3d.arcane;
	import away3d.events.Stage3DEvent;

	import flash.display.Stage3D;
	import flash.display3D.Context3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.Texture;
	import flash.display3D.textures.TextureBase;
	import flash.display3D.textures.TextureBase;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Rectangle;

	import org.osmf.events.BufferEvent;

	use namespace arcane;

	/**
	 * Stage3DProxy provides a proxy class to manage a single Stage3D instance as well as handling the creation and
	 * attachment of the Context3D (and in turn the back buffer) is uses. Stage3DProxy should never be created directly,
	 * but requested through Stage3DManager.
	 *
	 * @see away3d.core.managers.Stage3DProxy
	 *
	 * todo: consider moving all creation methods (createVertexBuffer etc) in here, so that disposal can occur here
	 * along with the context, instead of scattered throughout the framework
	 */
	public class Stage3DProxy extends EventDispatcher
	{
		private var _stage3D : Stage3D;
		arcane var _context3D : Context3D;
		arcane var _stage3DIndex : int = -1;
		private var _activeProgram3D : Program3D;
		private var _stage3DManager : Stage3DManager;
		private var _backBufferWidth : int;
		private var _backBufferHeight : int;
		private var _antiAlias : int;
		private var _enableDepthAndStencil : Boolean;
		private var _contextRequested : Boolean;
		private var _activeVertexBuffers : Vector.<VertexBuffer3D> = new Vector.<VertexBuffer3D>(8, true);
		private var _activeTextures : Vector.<TextureBase> = new Vector.<TextureBase>(8, true);

		/**
		 * Creates a Stage3DProxy object. This method should not be called directly. Creation of Stage3DProxy objects should
		 * be handled by Stage3DManager.
		 * @param stage3DIndex The index of the Stage3D to be proxied.
		 * @param stage3D The Stage3D to be proxied.
		 * @param stage3DManager
		 */
		public function Stage3DProxy(stage3DIndex : int, stage3D : Stage3D, stage3DManager : Stage3DManager)
		{
			_stage3DIndex = stage3DIndex;
			_stage3D = stage3D;
			_stage3D.viewPort = new Rectangle(0, 0, 1, 1);
			_stage3DManager = stage3DManager;
			_stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContext3DUpdate);
			requestContext();
		}

		public function setSimpleVertexBuffer(index : int, buffer : VertexBuffer3D, format : String = null) : void
		{
			// force setting null
			if (buffer && _activeVertexBuffers[index] == buffer) return;

			_context3D.setVertexBufferAt(index, buffer, 0, format);
			_activeVertexBuffers[index] = buffer;
		}

		public function setTextureAt(index : int, texture : TextureBase) : void
		{
			if (_activeTextures[index] == texture) return;

			_context3D.setTextureAt(index,  texture);

			_activeTextures[index] = texture;
		}

		public function setProgram(program3D : Program3D) : void
		{
			if (_activeProgram3D == program3D) return;
			_context3D.setProgram(program3D);
			_activeProgram3D = program3D;
		}

		/**
		 * Disposes the Stage3DProxy object, freeing the Context3D attached to the Stage3D.
		 */
		public function dispose() : void
		{
			_stage3DManager.removeStage3DProxy(this);
			_stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContext3DUpdate);
			_stage3D = null;
			_stage3DManager = null;
			_stage3DIndex = -1;
			freeContext3D();
		}

		/**
		 * Configures the back buffer associated with the Stage3D object.
		 * @param backBufferWidth The width of the backbuffer.
		 * @param backBufferHeight The height of the backbuffer.
		 * @param antiAlias The amount of anti-aliasing to use.
		 * @param enableDepthAndStencil Indicates whether the back buffer contains a depth and stencil buffer.
		 */
		public function configureBackBuffer(backBufferWidth : int, backBufferHeight : int, antiAlias : int, enableDepthAndStencil : Boolean) : void
		{
			_backBufferWidth = backBufferWidth;
			_backBufferHeight = backBufferHeight;
			_antiAlias = antiAlias;
			_enableDepthAndStencil = enableDepthAndStencil;

			if (_context3D)
				_context3D.configureBackBuffer(backBufferWidth, backBufferHeight, antiAlias, enableDepthAndStencil);
		}

		/**
		 * The index of the Stage3D which is managed by this instance of Stage3DProxy.
		 */
		public function get stage3DIndex() : int
		{
			return _stage3DIndex;
		}

		/**
		 * The Context3D object associated with the given Stage3D object.
		 */
		public function get context3D() : Context3D
		{
			return _context3D;
		}

		/**
		 * The viewport which dictates the region to which is rendered.
		 */
		public function get viewPort() : Rectangle
		{
			return _stage3D.viewPort;
		}

		public function set viewPort(value : Rectangle) : void
		{
			_stage3D.viewPort = value;
		}

		/**
		 * Frees the Context3D associated with this Stage3DProxy.
		 */
		private function freeContext3D() : void
		{
			if (_context3D) {
				_context3D.dispose();
				dispatchEvent(new Stage3DEvent(Stage3DEvent.CONTEXT3D_DISPOSED));
			}
			_context3D = null;
		}

		/**
		 * Called whenever the Context3D is retrieved or lost.
		 * @param event The event dispatched.
		 */
		private function onContext3DUpdate(event : Event) : void
		{
			if (_stage3D.context3D) {
				_context3D = _stage3D.context3D;
				_context3D.enableErrorChecking = true;
				_context3D.configureBackBuffer(_backBufferWidth, _backBufferHeight, _antiAlias, _enableDepthAndStencil);
				dispatchEvent(new Stage3DEvent(Stage3DEvent.CONTEXT3D_CREATED));
			}
			else {
				throw new Error("Rendering context lost!");
			}
		}

		/**
		 * Requests a Context3D object to attach to the managed Stage3D.
		 */
		private function requestContext() : void
		{
			_stage3D.requestContext3D();
			_contextRequested = true;
		}
	}
}
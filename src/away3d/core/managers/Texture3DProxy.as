﻿/** * Author: David Lenaerts */package away3d.core.managers{	import away3d.arcane;	import away3d.events.Stage3DEvent;	import away3d.materials.utils.MipmapGenerator;	import flash.display.BitmapData;	import flash.display3D.Context3DTextureFormat;	import flash.display3D.textures.Texture;	use namespace arcane;	public class Texture3DProxy	{		private static const MAX_SIZE : uint = 2048;		private var _bitmapData : BitmapData;		private var _textures : Vector.<Texture>;		private var _dirty : Vector.<Boolean>;		private var _maxIndex : int = -1;		private var _mipMapTex : BitmapData;		private var _listeningForDispose : Vector.<Stage3DProxy>;		// todo: remove mipMapTex option and keep mipmap holder cache?		public function Texture3DProxy(bitmapData : BitmapData = null)		{			_textures = new Vector.<Texture>(8);			_dirty = new Vector.<Boolean>(8);			_listeningForDispose = new Vector.<Stage3DProxy>(8);			if (bitmapData) this.bitmapData = bitmapData;		}		public function get bitmapData() : BitmapData		{			return _bitmapData;		}		public function set bitmapData(value : BitmapData) : void		{			if (value == _bitmapData) return;			if (!isBitmapDataValid(value, 1))				throw new Error("Invalid bitmapData! Must be power of 2 and not exceeding 2048");			if (_bitmapData) {				if (value.width != _bitmapData.width || value.height != _bitmapData.height)					invalidateSize();				else					invalidateContent();			}			_bitmapData = value;		}		public function invalidateContent() : void		{			for (var i : int = 0; i <= _maxIndex; ++i) {				_dirty[i] = true;			}		}		private function invalidateSize() : void		{			var tex : Texture;			for (var i : int = 0; i <= _maxIndex; ++i) {				tex = _textures[i];				if (tex) {					tex.dispose();					_textures[i] = null;					_dirty[i] = false;				}			}		}		public function dispose(deep : Boolean) : void		{			if (deep && _bitmapData) {				_bitmapData.dispose();				_bitmapData = null;			}			for (var i : int = 0; i <= _maxIndex; ++i)				if (_textures[i]) _textures[i].dispose();			for (i = 0; i < 8; ++i) {				if (_listeningForDispose[i]) {					_listeningForDispose[i].removeEventListener(Stage3DEvent.CONTEXT3D_DISPOSED, onContext3DDisposed);					_listeningForDispose[i] = null;				}			}		}		public function getTextureForStage3D(stage3DProxy : Stage3DProxy) : Texture		{			var contextIndex : int = stage3DProxy._stage3DIndex;			if (contextIndex > _maxIndex) _maxIndex = contextIndex;			var tex : Texture = _textures[contextIndex];			if (!_listeningForDispose[contextIndex]) {				stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_DISPOSED, onContext3DDisposed);				_listeningForDispose[contextIndex] = stage3DProxy;			}			if (!tex || _dirty[contextIndex]) {				if (!tex) _textures[contextIndex] = tex = stage3DProxy._context3D.createTexture(_bitmapData.width, _bitmapData.height, Context3DTextureFormat.BGRA, false);				MipmapGenerator.generateMipMaps(_bitmapData, tex, _mipMapTex, true);				_dirty[contextIndex] = false;			}			return tex;		}		private function onContext3DDisposed(event : Stage3DEvent) : void		{			var stage3DProxy : Stage3DProxy = Stage3DProxy(event.target);			var contextIndex : int = stage3DProxy._stage3DIndex;			if (_textures[contextIndex]) {				_textures[contextIndex].dispose();				_textures[contextIndex] = null;			}			_listeningForDispose[contextIndex] = null;			stage3DProxy.removeEventListener(Stage3DEvent.CONTEXT3D_DISPOSED, onContext3DDisposed);		}		private function isBitmapDataValid(bitmapData : BitmapData, id : uint = 0) : Boolean		{			if (bitmapData == null) return true;			var w : int = bitmapData.width;			var h : int = bitmapData.height;			if (w < 2 || h < 2 || w > MAX_SIZE || h > MAX_SIZE) return false;			if (isPowerOfTwo(w) && isPowerOfTwo(h)) return true;			return false;		}		private function isPowerOfTwo(value : int) : Boolean		{			return value ? ((value & -value) == value) : false;		}	}}
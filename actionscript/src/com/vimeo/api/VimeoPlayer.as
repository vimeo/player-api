/**
 * VimeoPlayer
 *
 * A wrapper class for Vimeo's video player (codenamed Moogaloop)
 * that allows you to embed easily into any AS3 application.
 *
 * Example on how to use:
 *  var vimeo_player = new VimeoPlayer([YOUR_APPLICATIONS_CONSUMER_KEY], 2, 400, 300);
 *  vimeo_player.addEventListener(VimeoPlayerEvent.COMPLETE, vimeoPlayerLoaded);
 *  addChild(vimeo_player);
 *
 * http://vimeo.com/api/docs/moogaloop
 *
 * Register your application for access to the Moogaloop API at:
 *
 * http://vimeo.com/api/applications
 */
package com.vimeo.api
{
	import com.vimeo.events.VimeoPlayerEvent;
	
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.system.Security;

	/**
	 * VIMEO Moogaloop Player Wrapper
	 * based on <https://github.com/vimeo/player-api>
	 * @author Tilman Griesel <tilman.griesel@dozeo.com>, Ryan Hefner <ryan@vimeo.com>
	 */
	public class VimeoPlayer extends Sprite
	{
		//--------------------------------------------------------------------------
		//
		//  Class Properties
		//
		//--------------------------------------------------------------------------

		// API v2
		public static const ERROR : String         = 'error';
		public static const FINISH : String         = 'finish';
		public static const LOAD_PROGRESS : String  = 'loadProgress';
		public static const PAUSE : String          = 'pause';
		public static const PLAY : String           = 'play';
		public static const PLAY_PROGRESS : String  = 'playProgress';
		public static const READY : String          = 'ready';
		public static const SEEK : String           = 'seek';
		
		// API v1
		public static const ON_FINISH : String      = 'onFinish';
		public static const ON_LOADING : String     = 'onLoading';
		public static const ON_PAUSE : String       = 'onPause';
		public static const ON_PLAY : String        = 'onPlay';
		public static const ON_PROGRESS : String    = 'onProgress';
		public static const ON_SEEK : String        = 'onSeek';
		
		//--------------------------------------------------------------------------
		//
		//  Instance Properties
		//
		//--------------------------------------------------------------------------
		
		// Default variables
		private var api_version : int       = 2;
		
		private var _ready:Boolean = false;
		private var _interactive:Boolean = true;
		
		// Player
		private var _moogaloopPlayer : Object;
		
		//--------------------------------------------------------------------------
		//
		//  Initialization
		//
		//--------------------------------------------------------------------------	
		
		public function VimeoPlayer(oauth_key:String, clip_id:int, w:int = 400, h:int = 300, fp_version:String='10', api_version:int=2)
		{
			this.setSize(w, h);
			
			// security settings
			Security.allowDomain('*');
			Security.allowInsecureDomain('*');
			
			// API selection
			var api_param : String = '';
			if (fp_version != '9')
			{
				switch(api_version)
				{
					case 2:
					{
						this.api_version = 2;
						api_param = '&api=1';
						break;						
					}
				}
			}
			else
			{
				this.api_version = 1;
				api_param = '&js_api=1';
			}
			
			// create url request
			var request : URLRequest = new URLRequest("http://api.vimeo.com/moogaloop_api.swf" +
														"?oauth_key=" + oauth_key +
														"&clip_id=" + clip_id +
														"&width=" + w +
														"&height=" + h +
														"&fullscreen=0" +
														"&fp_version=" + fp_version + api_param +
														"&cache_buster=" + (Math.random() * 1000));
			
			// create loader context
			var loaderContext : LoaderContext = new LoaderContext(true);
			
			var loader : Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loader_COMPLETE, false, 0, true);
			loader.load(request, loaderContext);
		}
		
		//--------------------------------------------------------------------------
		//
		//  API
		//  based on http://vimeo.com/api/docs/moogaloop-as
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Kills all video playback, events and objects in the player.
		 */
		public function destroy() : void
		{
			if(_moogaloopPlayer == null)
				return;
			
			// remove event listeners
			if (api_version == 2)
			{
				// API v2 Event Handlers
				_moogaloopPlayer.removeEventListener(READY, _moogaloopPlayer_READY, false, 0, true);
				_moogaloopPlayer.removeEventListener(PLAY, _moogaloopPlayer_PLAY, false, 0, true);
				_moogaloopPlayer.removeEventListener(PAUSE, _moogaloopPlayer_PAUSE, false, 0, true);
				_moogaloopPlayer.removeEventListener(SEEK, _moogaloopPlayer_SEEK, false, 0, true);
				_moogaloopPlayer.removeEventListener(LOAD_PROGRESS, _moogaloopPlayer_LOAD_PROGRESS, false, 0, true);
				_moogaloopPlayer.removeEventListener(PLAY_PROGRESS, _moogaloopPlayer_PLAY_PROGRESS, false, 0, true);
				_moogaloopPlayer.removeEventListener(FINISH, _moogaloopPlayer_FINISH, false, 0, true);
				_moogaloopPlayer.removeEventListener(ERROR, _moogaloopPlayer_ERROR, false, 0, true);
			}
			else
			{
				// API v1 Event Handlers
				_moogaloopPlayer.removeEventListener(ON_PLAY, _moogaloopPlayer_PLAY, false, 0, true);
				_moogaloopPlayer.removeEventListener(ON_PAUSE, _moogaloopPlayer_PAUSE, false, 0, true);
				_moogaloopPlayer.removeEventListener(ON_SEEK, _moogaloopPlayer_SEEK, false, 0, true);
				_moogaloopPlayer.removeEventListener(ON_LOADING, _moogaloopPlayer_LOAD_PROGRESS, false, 0, true);
				_moogaloopPlayer.removeEventListener(ON_PROGRESS, _moogaloopPlayer_PLAY_PROGRESS, false, 0, true);
				_moogaloopPlayer.removeEventListener(ON_FINISH, _moogaloopPlayer_FINISH, false, 0, true);
			}
			
			// remove the player from stage
			this.removeChild(_moogaloopPlayer as Sprite);
			
			// call player destroy
			_moogaloopPlayer.destroy();
			
			// nullify player
			_moogaloopPlayer = null;
			
			_ready = false;
		}
		
		/**
		 * Returns the hex color of the player.
		 */
		public function get color() : String
		{
			if(_moogaloopPlayer == null)
				return null;
			
			return _moogaloopPlayer.getColor();
		}
		
		/**
		 * Returns the elapsed time of the video in seconds. Accurate to 3 decimal places.
		 */
		public function get currentTime() : Number
		{
			if(_moogaloopPlayer == null)
				return -1;
			
			return _moogaloopPlayer.getCurrentTime();
		}

		/**
		 * Returns the duration of the video in seconds. Accurate to 3 decimal places after the video's
		 * metadata has been loaded; accurate to the second before the metadata has loaded.
		 */
		public function get duration() : Number
		{
			if(_moogaloopPlayer == null)
				return -1;
			
			return _moogaloopPlayer.getDuration();
		}
		
		/**
		 * Returns whether or not loop is turned on.
		 */
		public function get loop() : Boolean
		{
			if(_moogaloopPlayer == null)
				return false;
			
			return _moogaloopPlayer.getLoop();
		}
		
		/**
		 * Returns the iframe embed code for the video.
		 * */
		public function get videoEmbedCode() : String
		{
			if(_moogaloopPlayer == null)
				return null;
			
			return _moogaloopPlayer.getVideoEmbedCode();
		}
		
		/**
		 * Returns the Vimeo URL of the video.
		 * */
		public function get videoUrl() : String
		{
			if(_moogaloopPlayer == null)
				return null;
			
			return _moogaloopPlayer.getVideoUrl();
		}		

		/**
		 * Returns the player's current volume, a number between 0 and 1.
		 * */
		public function get volume() : Number
		{
			if(_moogaloopPlayer == null)
				return -1;
			
			return _moogaloopPlayer.getVolume();
		}	

		/**
		 * Loads a new video into the player based on the clip_id passed to the method.
		 * */
		public function loadVideo(clip_id:int) : void
		{
			if(_moogaloopPlayer == null)
				return;
			
			_moogaloopPlayer.loadVideo(clip_id);
		}

		/**
		 * Pauses the video.
		 * */
		public function pause() : void
		{
			if(_moogaloopPlayer == null)
				return;
			
			_moogaloopPlayer.pause();
		}

		/**
		 * Returns false if the video is playing, true otherwise.
		 * */
		public function get paused() : Boolean
		{
			if(_moogaloopPlayer == null)
				return true;
			
			return _moogaloopPlayer.paused();
		}

		/**
		 * Plays the video.
		 * */
		public function play() : void
		{
			if(_moogaloopPlayer == null)
				return;
			
			_moogaloopPlayer.play();
		}

		/**
		 * Seeks to the specified point in the video. Will maintain the same playing/paused state.
		 * The Flash player will not seek past the loaded point, while the HTML player will seek
		 * to that spot regardless of how much of the video has been loaded.
		 * */
		public function seek(seconds:Number):void
		{
			if(_moogaloopPlayer == null)
				return;
			
			_moogaloopPlayer.seek(seconds);
		}
		
		/**
		 * Sets the hex color of the player. Accepts both short and long hex codes.
		 * */
		public function set color(value:String):void
		{
			if(_moogaloopPlayer == null)
				return;
			
			_moogaloopPlayer.setColor(uint('0x' + value));
		}

		/**
		 * Toggles loop on or off.
		 * */
		public function set loop(value:Boolean):void
		{
			if(_moogaloopPlayer == null)
				return;
			
			_moogaloopPlayer.setLoop(value);
		}
		
		/**
		 * Sets the width and height of the player.
		 * */
		public function setSize(w:int, h:int) : void
		{
			this.width = w;
			this.height = h;
			
			// update bounds
			this.graphics.clear();
			this.graphics.drawRect(0, 0, w, h);
				
			// update player
			if(_moogaloopPlayer != null)
			{
				_moogaloopPlayer.setSize(w, h);
			}
		}
		
		/**
		 * Sets the volume of the player. Accepts a number between 0 and 1.
		 * */
		public function set volume(value:Number):void
		{
			if(_moogaloopPlayer == null)
				return;
			
			_moogaloopPlayer.setVolume(value);
		}
		
		
		/**
		 * Reverts the player back to the initial state.
		 * */
		public function unload():void
		{
			if(_moogaloopPlayer == null)
				return;
			
			_moogaloopPlayer.unload();
		}
		
		/**
		 * Sets player interaction. If false player will not handle any mouse interaction
		 * default is true
		 * */
		public function set interactive(value:Boolean):void
		{
			_interactive = value;
			updateInteractionMode();
		}
		
		/**
		 * Returns false if player interaction is disabled
		 * default is true
		 * */
		public function get interactive():Boolean
		{
			return _interactive;
		}
		
		/**
		 * Returns true if player is ready for use
		 * */
		public function get ready():Boolean
		{
			return _ready;
		}
		
		//--------------------------------------------------------------------------
		//
		//  Eventhandling
		//
		//--------------------------------------------------------------------------
		
		protected function loader_COMPLETE(event:Event):void
		{
			if(event.currentTarget.loader.content == null)
				return;
			
			// Finished loading moogaloop player into dummy
			_moogaloopPlayer = event.currentTarget.loader.content;
			this.addChild(_moogaloopPlayer as Sprite);
			
			if (api_version == 2)
			{
				// API v2 Event Handlers
				_moogaloopPlayer.addEventListener(READY, _moogaloopPlayer_READY, false, 0, true);
				_moogaloopPlayer.addEventListener(PLAY, _moogaloopPlayer_PLAY, false, 0, true);
				_moogaloopPlayer.addEventListener(PAUSE, _moogaloopPlayer_PAUSE, false, 0, true);
				_moogaloopPlayer.addEventListener(SEEK, _moogaloopPlayer_SEEK, false, 0, true);
				_moogaloopPlayer.addEventListener(LOAD_PROGRESS, _moogaloopPlayer_LOAD_PROGRESS, false, 0, true);
				_moogaloopPlayer.addEventListener(PLAY_PROGRESS, _moogaloopPlayer_PLAY_PROGRESS, false, 0, true);
				_moogaloopPlayer.addEventListener(FINISH, _moogaloopPlayer_FINISH, false, 0, true);
				_moogaloopPlayer.addEventListener(ERROR, _moogaloopPlayer_ERROR, false, 0, true);
			}
			else
			{
				// API v1 Event Handlers
				_moogaloopPlayer.addEventListener(ON_PLAY, _moogaloopPlayer_PLAY, false, 0, true);
				_moogaloopPlayer.addEventListener(ON_PAUSE, _moogaloopPlayer_PAUSE, false, 0, true);
				_moogaloopPlayer.addEventListener(ON_SEEK, _moogaloopPlayer_SEEK, false, 0, true);
				_moogaloopPlayer.addEventListener(ON_LOADING, _moogaloopPlayer_LOAD_PROGRESS, false, 0, true);
				_moogaloopPlayer.addEventListener(ON_PROGRESS, _moogaloopPlayer_PLAY_PROGRESS, false, 0, true);
				_moogaloopPlayer.addEventListener(ON_FINISH, _moogaloopPlayer_FINISH, false, 0, true);
			}
			
			// update interaction mode (allow mouse interactions)
			updateInteractionMode();
			
			// set ready state
			_ready = true;
			
			// dispatch complete event
			this.dispatchEvent(new VimeoPlayerEvent(VimeoPlayerEvent.COMPLETE));
		}
		
		protected function _moogaloopPlayer_READY(event:Event):void
		{
			this.dispatchEvent(new VimeoPlayerEvent(VimeoPlayerEvent.READY));
		}
		
		protected function _moogaloopPlayer_PLAY(event:Event):void
		{
			this.dispatchEvent(new VimeoPlayerEvent(VimeoPlayerEvent.PLAY));
		}
		
		protected function _moogaloopPlayer_PAUSE(event:Event):void
		{
			this.dispatchEvent(new VimeoPlayerEvent(VimeoPlayerEvent.PAUSE));
		}
		
		protected function _moogaloopPlayer_SEEK(event:Event):void
		{
			this.dispatchEvent(new VimeoPlayerEvent(VimeoPlayerEvent.SEEK));
		}
		
		protected function _moogaloopPlayer_LOAD_PROGRESS(event:Event):void
		{
			trace('Percent loaded: ' + Object(event).data.percent);
			// not implemented yet
		}
		
		protected function _moogaloopPlayer_PLAY_PROGRESS(event:Event):void
		{
			trace('Percent played: ' + Object(event).data.percent);
			// not implemented yet
		}
		
		protected function _moogaloopPlayer_FINISH(event:Event):void
		{
			this.dispatchEvent(new VimeoPlayerEvent(VimeoPlayerEvent.FINISH));
		}
		
		protected function _moogaloopPlayer_ERROR(event:Event):void
		{
			this.dispatchEvent(new VimeoPlayerEvent(VimeoPlayerEvent.ERROR));
		}
		
		//--------------------------------------------------------------------------
		//
		//  Methods
		//
		//--------------------------------------------------------------------------
		
		private function updateInteractionMode():void
		{
			if(_moogaloopPlayer == null)
				return;
			
			var player:Sprite = _moogaloopPlayer as Sprite;
			
			if(!_interactive)
			{
				player.mouseChildren = false;
				player.mouseEnabled = false;
				// hide the player ui
				trace('set mouse out');
				_moogaloopPlayer.mouseOut();
			}
			else
			{
				player.mouseChildren = true;
				player.mouseEnabled = true;
			}
		}
	}
}
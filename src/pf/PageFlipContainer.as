package pf
{
	import flash.display.Bitmap;
	import flash.geom.Point;
	
	import starling.display.Graphics;
	import starling.display.Image;
	import starling.display.QuadBatch;
	import starling.display.Shape;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;

	/**
	 *
	 * @original-author shaorui
	 * 
	 */	
	public class PageFlipContainer extends Sprite
	{
		
		
		private var cacheImage:Image;
		
		private var flipImage:ImagePage;
		
		private var textures:Vector.<Texture>;
		
		private var isDraging:Boolean = false;
		
		private var bookWidth:Number;
		
		private var bookHeight:Number;
		
		private var pageCount:Number;
		
		private var quadBatch:QuadBatch;
		
		private var leftPageNum:int = -1;
		
		private var rightPageNum:int = 0;
		
		private var flipingPageNum:int = -1;
		
		public var flipingPageLocationX:Number = -1;
		
		public var flipingPageLocationY:Number = -1;
		
		public var begainPageLocationX:Number = -1;
		
		public var begainPageLocationY:Number = -1;
		
		private var needUpdate:Boolean = true;
		
		private var debugGraphics:Graphics;
		private var debugShape:Shape;
		
		public function PageFlipContainer(_textures:Vector.<Texture>, _bookWidth:Number, _bookHeight:Number, _bookCount:Number)
		{
			super();
			this.textures = _textures;
			this.bookWidth = _bookWidth;
			this.bookHeight = _bookHeight;
			this.pageCount = _textures.length;
			
			
			debugShape = new Shape();
			
			this.debugGraphics = debugShape.graphics;
			
			initPage();
		}
		
		private function initPage():void
		{
			quadBatch = new QuadBatch();
			addChild(quadBatch);
			
			cacheImage = new Image(textures[0]);
			flipImage = new ImagePage(textures[0], debugGraphics);
			addEventListener(Event.ENTER_FRAME,enterFrameHandler);
			addEventListener(Event.ADDED_TO_STAGE,firstFrameInit);
			addEventListener(TouchEvent.TOUCH,onTouchHandler);
		}
		
		private function firstFrameInit():void
		{
			removeEventListener(Event.ADDED_TO_STAGE,firstFrameInit);
			enterFrameHandler();
			needUpdate = false;
		}
		
		
		
		private function enterFrameHandler(event:Event=null):void
		{
			if(stage == null || !needUpdate) {
				return;
			}
			
			quadBatch.reset();
			
			if(flipingPageNum >= 0)
			{
				leftPageNum = flipingPageNum - 1;
				rightPageNum = flipingPageNum + 2;
			}
			
			if(validatePageNumber(leftPageNum))
			{
				cacheImage.x = 0;
				cacheImage.texture = textures[leftPageNum];
				quadBatch.addImage(cacheImage);
			}
			
			if(validatePageNumber(rightPageNum))
			{
				cacheImage.x = bookWidth/2;
				cacheImage.texture = textures[rightPageNum];
				quadBatch.addImage(cacheImage);
			}
			
			if(validatePageNumber(flipingPageNum))
			{
				if(flipImage.softMode)
				{
					flipImage.texture = begainPageLocationX>=0?textures[flipingPageNum]:textures[flipingPageNum+1];
					flipImage.anotherTexture = begainPageLocationX<0?textures[flipingPageNum]:textures[flipingPageNum+1];
					flipImage.readjustSize();
					flipImage.setLocationSoft(quadBatch,begainPageLocationX,begainPageLocationY,flipingPageLocationX,flipingPageLocationY);
				}
				else
				{
					flipImage.texture = flipingPageLocationX>=0?textures[flipingPageNum]:textures[flipingPageNum+1];
					flipImage.readjustSize();
					flipImage.setLocation(flipingPageLocationX);
					quadBatch.addImage(flipImage);
				}
			}
		}
		
		
		
		private function onTouchHandler(event:TouchEvent):void
		{
			var touch:Touch = event.getTouch(this);
			if(touch != null && (touch.phase == TouchPhase.BEGAN || touch.phase == TouchPhase.MOVED || touch.phase == TouchPhase.ENDED))
			{
				var point:Point = touch.getLocation(this);
				var imgWidth:Number = bookWidth/2;
				var imgHeight:Number = bookHeight/2;
				if(touch.phase == TouchPhase.BEGAN)
				{
					begainPageLocationX = (point.x-imgWidth)/imgWidth;
					begainPageLocationY = (point.y-imgHeight)/imgHeight;
					isDraging = true;
					if(point.x >= imgWidth)
					{
						if(validatePageNumber(rightPageNum))
						{
							flipingPageNum = rightPageNum;
						}
					}
					else
					{
						if(validatePageNumber(leftPageNum))
						{
							flipingPageNum = leftPageNum-1;
						}
					}
					resetSoftMode();
					if(flipImage.softMode && !flipImage.validateBegainPoint(begainPageLocationX,begainPageLocationY))
					{
						isDraging = false;
						flipingPageNum = -1;
						return;
					}
				}
				else if(touch.phase == TouchPhase.MOVED)
				{
					if(isDraging)
					{
						flipingPageLocationX = (point.x-imgWidth)/imgWidth;
						flipingPageLocationY = (point.y-imgHeight)/imgHeight;
						if(flipingPageLocationX > 1)
							flipingPageLocationX = 1;
						if(flipingPageLocationX < -1)
							flipingPageLocationX = -1;
						if(flipingPageLocationY > 1)
							flipingPageLocationY = 1;
						if(flipingPageLocationY < -1)
							flipingPageLocationY = -1;
						validateNow();
					}
				}
				else
				{
					if(isDraging)
					{
						finishTouchByMotion(point.x);
						isDraging = false;
					}
				}
			}
			else
			{
				needUpdate = false;
			}
		}
		
		private function resetSoftMode():void
		{
			if(flipingPageNum > 0 && flipingPageNum < (pageCount-2))
				flipImage.softMode = true;
			else
				flipImage.softMode = false;
		}
		
		private function finishTouchByMotion(endX:Number):void
		{
			var imgWidth:Number = bookWidth/2;
			needUpdate = true;
			touchable = false;
			addEventListener(Event.ENTER_FRAME,executeMotion);
			function executeMotion(event:Event):void
			{
				if(endX >= imgWidth)
				{
					flipingPageLocationX += (1-flipingPageLocationX)/4;
					flipingPageLocationY = flipingPageLocationX;
					if(flipingPageLocationX >= 0.999)
					{
						flipingPageLocationX = 1;
						flipingPageLocationY = 1;
						removeEventListener(Event.ENTER_FRAME,executeMotion);
						tweenCompleteHandler();
					}
				}
				else
				{
					flipingPageLocationX += (-1-flipingPageLocationX)/4;
					flipingPageLocationY = -flipingPageLocationX;
					if(flipingPageLocationX <= -0.999)
					{
						flipingPageLocationX = -1;
						flipingPageLocationY = 1;
						removeEventListener(Event.ENTER_FRAME,executeMotion);
						tweenCompleteHandler();
					}
				}
			}
		}
		
		private function tweenCompleteHandler():void
		{
			if(flipingPageLocationX == 1)
			{
				leftPageNum = flipingPageNum-1;
				rightPageNum = flipingPageNum;
			}
			else if(flipingPageLocationX == -1)
			{
				leftPageNum = flipingPageNum+1;
				rightPageNum = flipingPageNum+2;
			}
			flipingPageNum = -1;
			resetSoftMode();
			validateNow();
			touchable = true;
			debugGraphics.clear();
		}
		
		private function validatePageNumber(pageNum:int):Boolean
		{
			if(pageNum >= 0 && pageNum < pageCount)
				return true;
			else
				return false;
		}
		
		public function get pageNumber():int
		{
			if(leftPageNum >= 0)
				return leftPageNum;
			else
				return rightPageNum;
		}
		
		public function validateNow():void
		{
			needUpdate = true;
			enterFrameHandler();
			needUpdate = false;
		}
		
		public function gotoPage(pn:int):void
		{
			if(pn < 0)
				pn = 0;
			if(pn >= pageCount)
				pn = pageCount-1;
			if(pn == 0)
			{
				leftPageNum = -1;
				rightPageNum = 0;
			}
			else if(pn == pageCount-1)
			{
				leftPageNum = pn;
				rightPageNum = -1;
			}
			else
			{
				if(pn%2==0)
					pn = pn - 1;
				leftPageNum = pn;
				rightPageNum = pn+1;
			}
			flipingPageNum = -1;
			resetSoftMode();
			validateNow();
		}
	}
}
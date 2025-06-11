
// ##############################################################
// # CONSTANT MACROS
// ##############################################################

/// Fixed-mode identifiers – tell the scaler which dimension
/// must stay constant when the browser’s aspect ratio changes.
#macro VIEW_SCALER_FIXED_MODE_SAFE			"safe_zone"		/* fit inside “safe zone” */
#macro VIEW_SCALER_FIXED_MODE_WIDTH			"custom_width"	/* keep given width */
#macro VIEW_SCALER_FIXED_MODE_HEIGHT		"custom_height"	/* keep given height */
#macro VIEW_SCALER_FIXED_MODE_ROOM_WIDTH	"room_width"	/* keep room_width */
#macro VIEW_SCALER_FIXED_MODE_ROOM_HEIGHT	"room_height"	/* keep room_height */

/// Horizontal alignment options (relative to the anchor point).
#macro VIEW_SCALER_ALIGN_LEFT	0	/* anchor at left edge */
#macro VIEW_SCALER_ALIGN_CENTER 1	/* anchor at centre */
#macro VIEW_SCALER_ALIGN_RIGHT	2	/* anchor at right edge */

/// Vertical alignment options (relative to the anchor point).
#macro VIEW_SCALER_ALIGN_TOP	0	/* anchor at top edge */
#macro VIEW_SCALER_ALIGN_MIDDLE 1	/* anchor at centre */
#macro VIEW_SCALER_ALIGN_BOTTOM 2	/* anchor at bottom edge */


// ##############################################################
// # INTERNAL UTILITIES
// ##############################################################

/// @function _view_scaler_fetch_state()
/// @desc Returns the singleton struct that stores the current
/// view-scaler configuration (anchor, size, alignment, etc.).
/// @returns {struct}
/// @ignore
function _view_scaler_fetch_state()
{
	static _data = {
		// position
		x: 0,
		y: 0,
		// scale
		width: 0,
		height: 0,
		// alignment
		h_align: VIEW_SCALER_ALIGN_LEFT,
		v_align: VIEW_SCALER_ALIGN_TOP,
		// fixe mode (allows to keep a fixed dimension)
		fixed_mode: VIEW_SCALER_FIXED_MODE_WIDTH,
		fixed_value: room_width / 2,
		// internal offset computations
		x_offset: 0,
		y_offset: 0,
		// camera
		camera_index: 0
	};
	
	return _data;
}

/// @function _view_scaler_refresh()
/// @desc Recalculates view size, position, viewport, window size
/// and application surface to satisfy the current scaler state.
/// Called automatically by the other helpers; you never call
/// this directly.
/// @ignore
function _view_scaler_refresh()
{
	static _state = _view_scaler_fetch_state();

	with (_state)
	{	
		var _cam = view_get_camera(camera_index);
		
		var _ratio = browser_width/browser_height

		//Eneable views
		view_enabled = true
		view_visible[0] = true;

		switch(fixed_mode)
		{
			case VIEW_SCALER_FIXED_MODE_SAFE:
		
				if(width / height > _ratio)
				{
					height = width / _ratio;
				}
				else
				{
					width = height * _ratio;
				}
				break;
	
			case VIEW_SCALER_FIXED_MODE_ROOM_WIDTH:
				fixed_value = room_width
			case VIEW_SCALER_FIXED_MODE_WIDTH:
				width = fixed_value
				height = fixed_value / _ratio
				break;

			case VIEW_SCALER_FIXED_MODE_ROOM_HEIGHT:
				fixed_value = room_height 
			case VIEW_SCALER_FIXED_MODE_HEIGHT:
				width = fixed_value * _ratio
				height = fixed_value
				break;

			default:
				show_message_async("_view_scaler_refresh :: fixed_mode wrong value");
				return;
	
		}

		camera_set_view_size(_cam, width, height);

		var _align = h_align + v_align * 3
		switch(_align)
		{
	
			case 0:
				x_offset = 0 
				y_offset = 0
				break;

			case 1:
				x_offset = -width/2
				y_offset = 0
				break;

			case 2:
				x_offset = -width
				y_offset = 0
				break;

			case 3:
				x_offset = 0 
				y_offset = -height/2
				break;

			case 4:
				x_offset = -width/2
				y_offset = -height/2
				break;

			case 5:
				x_offset = -width
				y_offset = -height/2
				break;

			case 6:
				x_offset = 0
				y_offset = -height
				break;

			case 7:
				x_offset = -width/2
				y_offset = -height
				break;

			case 8:
				x_offset = -width
				y_offset = -height
				break;
			
			default:
				show_message_async("_view_scaler_refresh :: alignment wrong value");
				return;
		}

		camera_set_view_pos(_cam, x + x_offset, y + y_offset)

		view_scaler_resize_canvas(width, height, function(json) {
			try {
				var _data = json_parse(json);
	
				var _w = _data.width, _h = _data.height, _x = _data.x, _y = _data.y;
				
				view_wport[0] = _w;
				view_hport[0] = _h;
				window_set_size(_w, _h);
				window_set_position(_x, _y);
				surface_resize(application_surface, _w, _h);
			}
			catch (_ex) {
				show_message_async("_view_scaler_refresh :: failed to parse JSON from extension");
				return;
			}
		});
	}
}


// ##############################################################
// # PUBLIC SETUP HELPERS
// ##############################################################

/// @function view_scaler_align(h_align,v_align)
/// @desc Re-positions the current view by changing its horizontal
/// and vertical alignment while preserving its size and anchor.
/// @param {real} _h_align New horizontal alignment (VIEW_SCALER_ALIGN_LEFT / _CENTER / _RIGHT)
/// @param {real} _v_align New vertical alignment (VIEW_SCALER_ALIGN_TOP / _MIDDLE / _BOTTOM)
function view_scaler_align(_h_align, _v_align)
{
	if (os_browser == browser_not_a_browser) return undefined;
	
	static _state = _view_scaler_fetch_state();
	
	_state.h_align = _h_align
	_state.v_align = _v_align

	_view_scaler_refresh()
}

/// @function view_scaler_custom_height(x, y, h_align, v_align, height)
/// @desc Creates a view whose **height** is fixed to 
/// `_height` (world units) while its width expands or shrinks to match the browser’s current aspect ratio.
/// @param {real} _x World X coordinate of the anchor point
/// @param {real} _y World Y coordinate of the anchor point
/// @param {real} _h_align Horizontal alignment (VIEW_SCALER_ALIGN_*)
/// @param {real} _v_align Vertical alignment (VIEW_SCALER_ALIGN_*)
/// @param {real} _height  Fixed view height in world units
function view_scaler_custom_height(_x, _y, _h_align, _v_align, _height)
{
	if (os_browser == browser_not_a_browser) return undefined;
	
	static _state = _view_scaler_fetch_state();

	_state.x = _x;
	_state.y = _y;
	_state.h_align = _h_align;
	_state.v_align = _v_align;
	_state.fixed_mode = VIEW_SCALER_FIXED_MODE_HEIGHT;
	_state.fixed_value = _height;

	_view_scaler_refresh();
}

/// @function view_scaler_custom_width(x, y, h_align, v_align, width)
/// @desc Creates a view whose **width** is fixed to
/// `_width` (world units) while its height is scaled to maintain aspect ratio.
/// @param {real} _x World X coordinate of the anchor point
/// @param {real} _y World Y coordinate of the anchor point
/// @param {real} _h_align Horizontal alignment (VIEW_SCALER_ALIGN_*)
/// @param {real} _v_align Vertical alignment   (VIEW_SCALER_ALIGN_*)
/// @param {real} _width   Fixed view width in world units
function view_scaler_custom_width(_x, _y, _h_align, _v_align, _width)
{
	if (os_browser == browser_not_a_browser) return undefined;
	
	static _state = _view_scaler_fetch_state();

	_state.x = _x
	_state.y = _y
	_state.h_align = _h_align
	_state.v_align = _v_align
	_state.fixed_mode = VIEW_SCALER_FIXED_MODE_WIDTH
	_state.fixed_value = _width

	_view_scaler_refresh()
}

/// @function view_scaler_custom_safe_zone(x, y, width, height)
/// @desc Ensures the rectangle defined by `width` × `height`
/// centred on (`_x`,`_y`) **always remains visible** regardless of browser aspect ratio. Extra space is added
/// as letter-/pillar-boxes when necessary.
/// @param {real} _x Centre X coordinate of the safe-zone
/// @param {real} _y Centre Y coordinate of the safe-zone
/// @param {real} _width  Safe-zone width  in world units
/// @param {real} _height Safe-zone height in world units
function view_scaler_custom_safe_zone(_x, _y, _width, _height)
{
	if (os_browser == browser_not_a_browser) return undefined;
	
	static _state = _view_scaler_fetch_state();

	_state.x = _x;
	_state.y = _y;
	_state.h_align = VIEW_SCALER_ALIGN_CENTER;
	_state.v_align = VIEW_SCALER_ALIGN_MIDDLE;
	_state.fixed_mode = VIEW_SCALER_FIXED_MODE_SAFE;
	_state.width = _width;
	_state.height = _height;

	_view_scaler_refresh();
}

/// @function view_scaler_resize(fixed_value)
/// @desc Changes the **current** fixed dimension (width or height,
/// depending on `fixed_mode`) to `_fixed_value` and reapplies scaling immediately.
/// @param {real} _fixed_value New size for the fixed dimension in world units
function view_scaler_resize(_fixed_value)
{	
	if (os_browser == browser_not_a_browser) return undefined;
	
	static _state = _view_scaler_fetch_state();

	_state.fixed_value = _fixed_value

	_view_scaler_refresh()
}

/// @function view_scaler_move(x, y)
/// @desc Moves the view’s anchor to the new world position while keeping
/// its size and alignment unchanged.
/// @param {real} _x New anchor X coordinate
/// @param {real} _y New anchor Y coordinate
function view_scaler_move(_x, _y)
{	
	if (os_browser == browser_not_a_browser) return undefined;
	
	static _state = _view_scaler_fetch_state();

	_state.x = _x;
	_state.y = _y;

	with (_state)
	{	
		var _cam = view_get_camera(camera_index);
		
		camera_set_view_pos(_cam, x + x_offset, y + y_offset);
	}
}

/// @function view_scaler_room_height()
/// @desc Scales the view so its height exactly matches `room_height`,
/// then adjusts width for aspect ratio. Anchor is top-left corner of the room.
function view_scaler_room_height()
{	
	if (os_browser == browser_not_a_browser) return undefined;
	
	static _state = _view_scaler_fetch_state();

	_state.x = 0;
	_state.y = 0;
	_state.h_align = VIEW_SCALER_ALIGN_LEFT;
	_state.v_align = VIEW_SCALER_ALIGN_TOP;
	_state.fixed_mode = VIEW_SCALER_FIXED_MODE_ROOM_HEIGHT;

	_view_scaler_refresh()
}

/// @function view_scaler_room_width()
/// @desc Scales the view so its width exactly matches `room_width`,
/// then adjusts height for aspect ratio. Anchor is top-left corner of the room.
function view_scaler_room_width()
{	
	if (os_browser == browser_not_a_browser) return undefined;
	
	static _state = _view_scaler_fetch_state();

	_state.x = 0;
	_state.y = 0;
	_state.h_align = VIEW_SCALER_ALIGN_LEFT;
	_state.v_align = VIEW_SCALER_ALIGN_TOP;
	_state.fixed_mode = VIEW_SCALER_FIXED_MODE_ROOM_WIDTH;

	_view_scaler_refresh()
}

/// @function view_scaler_room_safe_zone()
/// @desc Centres the view on the room and expands it just enough for the
/// entire room to stay visible inside the browser window, adding side/top bars if aspect ratios differ.
function view_scaler_room_safe_zone()
{
	if (os_browser == browser_not_a_browser) return undefined;
	
	static _state = _view_scaler_fetch_state();

	_state.x = room_width / 2;
	_state.y = room_height / 2;
	_state.h_align = VIEW_SCALER_ALIGN_CENTER;
	_state.v_align = VIEW_SCALER_ALIGN_MIDDLE;
	_state.fixed_mode = VIEW_SCALER_FIXED_MODE_SAFE;
	_state.width = room_width;
	_state.height = room_height;

	_view_scaler_refresh()
}

/// @function view_scaler_get_bottom()
/// @desc World Y coordinate of the **bottom edge** of the current view.
/// @pure
/// @returns {real}
function view_scaler_get_bottom()
{
	if (os_browser == browser_not_a_browser) return undefined;
	
	static _state = _view_scaler_fetch_state();
	
	var _cam = view_get_camera(_state.camera_index);

	return camera_get_view_y(_cam) + camera_get_view_height(_cam);
}

/// @function view_scaler_get_center()
/// @desc World X coordinate of the view’s horizontal centre.
/// @pure
/// @returns {real}
function view_scaler_get_center()
{
	if (os_browser == browser_not_a_browser) return undefined;
	
	static _state = _view_scaler_fetch_state();
	
	var _cam = view_get_camera(_state.camera_index);

	return camera_get_view_x(_cam) + camera_get_view_width(_cam) / 2;
}

/// @function view_scaler_get_fixed_value()
/// @desc The size (width or height) that is currently forced to stay constant according to `fixed_mode`.
/// @pure
/// @returns {real}
function view_scaler_get_fixed_value()
{
	if (os_browser == browser_not_a_browser) return undefined;
	
	static _state = _view_scaler_fetch_state();

	return _state.fixed_value;
}

/// @function view_scaler_get_left()
/// @desc World X coordinate of the **left edge** of the current view.
/// @pure
/// @returns {real}
function view_scaler_get_left()
{
	if (os_browser == browser_not_a_browser) return undefined;
	
	static _state = _view_scaler_fetch_state();
	
	var _cam = view_get_camera(_state.camera_index);

	return camera_get_view_x(_cam);
}

/// @function view_scaler_get_middle()
/// @desc World Y coordinate of the view’s vertical centre.
/// @pure
/// @returns {real}
function view_scaler_get_middle()
{
	if (os_browser == browser_not_a_browser) return undefined;
	
	static _state = _view_scaler_fetch_state();
	
	var _cam = view_get_camera(_state.camera_index);

	return camera_get_view_y(_cam) + camera_get_view_height(_cam) / 2;
}

/// @function view_scaler_get_right()
/// @desc World X coordinate of the **right edge** of the current view.
/// @pure
/// @returns {real}
function view_scaler_get_right()
{
	if (os_browser == browser_not_a_browser) return undefined;
	
	static _state = _view_scaler_fetch_state();
	
	var _cam = view_get_camera(_state.camera_index);

	return camera_get_view_x(_cam) + camera_get_view_width(_cam);
}

/// @function view_scaler_get_top()
/// @desc World Y coordinate of the **top edge** of the current view.
/// @pure
/// @returns {real}
function view_scaler_get_top()
{
	if (os_browser == browser_not_a_browser) return undefined;
	
	static _state = _view_scaler_fetch_state();
	
	var _cam = view_get_camera(_state.camera_index);

	return camera_get_view_y(_cam);
}

/// @function view_scaler_get_height()
/// @desc Current view height in world units.
/// @pure
/// @returns {real}
function view_scaler_get_height()
{
	if (os_browser == browser_not_a_browser) return undefined;
	
	static _state = _view_scaler_fetch_state();
	
	var _cam = view_get_camera(_state.camera_index);

	return camera_get_view_height(_cam);
}

/// @function view_scaler_get_width()
/// @desc Current view width in world units.
/// @pure
/// @returns {real}
function view_scaler_get_width()
{
	if (os_browser == browser_not_a_browser) return undefined;
	
	static _state = _view_scaler_fetch_state();
	
	var _cam = view_get_camera(_state.camera_index);
	
	return camera_get_view_width(_cam);
}

/// @function view_scaler_get_x()
/// @desc X coordinate of the view’s **anchor point** (not necessarily the left edge—depends on alignment).
/// @pure
/// @returns {real}
function view_scaler_get_x()
{
	if (os_browser == browser_not_a_browser) return undefined;
	
	static _state = _view_scaler_fetch_state();

	return _state.x;
}

/// @function view_scaler_get_y()
/// @desc Y coordinate of the view’s **anchor point** (not necessarily the top edge—depends on alignment).
/// @pure
/// @returns {real}
function view_scaler_get_y()
{
	if (os_browser == browser_not_a_browser) return undefined;
	
	static _state = _view_scaler_fetch_state();

	return _state.y;
}

   
// ##############################################################
// # GUI-MOUSE HELPERS
// ##############################################################

/// @function mouse_gui_x()
/// @description Returns the current mouse X coordinate in **GUI space**
///              (0 → display_get_gui_width()).  
///              • On desktop targets it forwards to `device_mouse_x_to_gui`.  
///              • On HTML5 it compensates for the active view-scaler so the
///                value matches what you would get in native builds.
/// @pure
/// @returns {real} Mouse X position in GUI pixels
function mouse_gui_x() {
	if (os_browser == browser_not_a_browser) 
		return device_mouse_x_to_gui(0);
		
	return view_scaler_mouse_x_to_gui(mouse_x);
}

/// @function mouse_gui_y()
/// @description Returns the current mouse Y coordinate in **GUI space**
///              (0 → display_get_gui_height()), automatically adapting for
///              the view-scaler on HTML5 as explained for `mouse_gui_x`.
/// @pure
/// @returns {real} Mouse Y position in GUI pixels
function mouse_gui_y() {
	if (os_browser == browser_not_a_browser)
		return device_mouse_y_to_gui(0);
	
	return view_scaler_mouse_y_to_gui(mouse_y);
}

/// @function view_scaler_mouse_x_from_gui(_x_gui)
/// @description Converts an X coordinate measured in GUI pixels into a
///              **world-space** X coordinate that matches the scaled view.
/// @param {real} _x_gui X position in GUI pixels
/// @pure
/// @returns {real} Equivalent world-space X coordinate
function view_scaler_mouse_x_from_gui(_x_gui) {
	return view_scaler_get_left() + _x_gui / display_get_gui_width() * view_scaler_get_width();
}

/// @function view_scaler_mouse_x_to_gui(_x)
/// @description Converts a **world-space** X coordinate into GUI pixels,
/// suitable for drawing UI elements that track game objects.
/// @param {real} _x World-space X coordinate
/// @pure
/// @returns {real} Equivalent X position in GUI pixels
function view_scaler_mouse_x_to_gui(_x) {
	return (_x - view_scaler_get_left()) / view_scaler_get_width() * display_get_gui_width();
}

/// @function view_scaler_mouse_y_from_gui(_y_gui)
/// @description Converts a Y coordinate measured in GUI pixels into a
/// **world-space** Y coordinate under the current view-scaler.
/// @param {real} _y_gui Y position in GUI pixels
/// @pure
/// @returns {real} Equivalent world-space Y coordinate
function view_scaler_mouse_y_from_gui(_y_gui) {
	return view_scaler_get_top() + _y_gui / display_get_gui_height() * view_scaler_get_height();
}

/// @function view_scaler_mouse_y_to_gui(_y)
/// @desc Converts a **world-space** Y coordinate into GUI pixels so
/// you can position GUI elements relative to in-game objects.
/// @param {real} _y World-space Y coordinate
/// @pure
/// @returns {real} Equivalent Y position in GUI pixels
function view_scaler_mouse_y_to_gui(_y) {
	return (_y - view_scaler_get_top()) / view_scaler_get_height() * display_get_gui_height();
}

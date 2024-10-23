-- An mp3 streaming widget for the Awesome Window Manager
-- https://github.com/Luz/mp3-stream-widget

local awful = require("awful")
local wibox = require("wibox")
local naughty = require("naughty")
local watch = require("awful.widget.watch")

-- We use streams_pid variable globally, otherwise some stuff is called twice, as there are two widgets for two desktops
local streams_pid = ""
local is_playing = false

local mp3streamer = {}

local function worker(user_args)
	local args = user_args or {}
	local WIDGET_DIR = os.getenv("HOME") .. '/.config/awesome/mp3-stream-widget/'
	local play_icon = args.play_icon or WIDGET_DIR .. 'play.svg'
	local stop_icon = args.stop_icon or WIDGET_DIR .. 'stop.svg'
	local font = args.font or 'Play 8'
	local STREAM = args.stream or "https://rautemusik-de-hz-fal-stream12.radiohost.de/metal_mp3-192"
	local TOOL = args.tool or "mplayer"

	local START_STREAM = TOOL .. " " .. STREAM
	local GET_STREAMS_PID = "pgrep -fx '" .. START_STREAM .. "'"

	-- Note that the double quotes in the string START_STOP_STREAM are escaped:
	local START_STOP_STREAM = string.format([[bash -c '
		START_STREAM="%s"
		PID=$(eval "pgrep -fx \"$START_STREAM\"")
		if [ -z $PID ]; then
			eval $START_STREAM
		else
			kill $PID
		fi
	']], START_STREAM)

	mp3streamer = wibox.widget {
		{
			id = 'songw',
			font = font,
			widget = wibox.widget.textbox,
			text = "default"
		},
		{
		id = "icon",
			widget = wibox.widget.imagebox,
			image = play_icon,
		},
		layout = wibox.layout.align.horizontal,
		update_widget = function(self, streams_pid_new)
			-- Detect changes of the pid:
			if streams_pid ~= streams_pid_new and streams_pid == "" then
				naughty.notify({ title = "mp3streamer", text = "Just started, please wait a bit" })
			end
			-- Store the new pid for future change detection:
			streams_pid = streams_pid_new

			local text_displayed = ""
			if #streams_pid > 0 then
				is_playing = true
			--	text_displayed = "pid: " .. streams_pid
			else
				is_playing = false
			--	text_displayed = "mplayer off"
			end

			self:get_children_by_id('icon')[1]:set_image(is_playing and stop_icon or play_icon)

			if self:get_children_by_id('songw')[1]:get_markup() ~= text_displayed then
				self:get_children_by_id('songw')[1]:set_markup(text_displayed)
			end
		end
	}
	local update_widget_text = function(widget, stdout, _, _, _)
		widget:update_widget(stdout)
	end

	watch(GET_STREAMS_PID, timeout, update_widget_text, mp3streamer)

	mp3streamer:connect_signal("button::press", function(_, _, _, button)
		if (button == 1) then -- Left click
			awful.spawn(START_STOP_STREAM, false)
		--elseif (button == 3) then -- Right click
		end
	end)

	return mp3streamer
end

return setmetatable(mp3streamer, { __call = function(_, ...)
    return worker(...)
end })

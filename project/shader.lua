local Shader = {}

Shader.pixelateTextShader = love.graphics.newShader [[
	extern float threshold;
	vec4 effect(vec4 colour, Image image, vec2 texture_coords, vec2 pixel_coords)
    {
		vec4 cPixel = Texel(image, texture_coords);
		return vec4(cPixel[0]*colour[0], cPixel[1]*colour[1], cPixel[2]*colour[2], colour[3]*ceil(cPixel[3] - threshold));
	}
]]

return Shader
local Shader = {}

Shader.pixelateTextShader = love.graphics.newShader [[
	extern float threshold;
	vec4 effect(vec4 colour, Image image, vec2 texture_coords, vec2 pixel_coords)
    {
		vec4 cPixel = Texel(image, texture_coords);
		return vec4(cPixel[0]*colour[0], cPixel[1]*colour[1], cPixel[2]*colour[2], colour[3]*ceil(cPixel[3] - threshold));
	}
]]

Shader.glow = love.graphics.newShader [[
	extern number glowSize;
	extern vec4 innerColour;
	extern vec4 outerColour;
	extern vec4 borderColour;
	extern number borderSize;
	extern vec2 imageDimensions;
	
	vec4 effect(vec4 colour, Image image, vec2 texture_coords, vec2 pixel_coords)
    {
		int glowSizeInt = int(ceil(glowSize));
		number closestDist = glowSizeInt + borderSize + 1;
		for (int i = -glowSizeInt; i <= glowSizeInt; i++) {
			for (int j = -glowSizeInt; j <= glowSizeInt; j++) {
				vec2 oCoords = vec2(float(i)/imageDimensions[0] + texture_coords[0], float(j)/imageDimensions[1] + texture_coords[1]);
				vec4 oPix = Texel(image, oCoords);
				if (oPix[3] > 0) {
					closestDist = min(sqrt(pow(i, 2) + pow(j, 2)), closestDist);
				}
			}
		}
		
		if (closestDist == 0 || closestDist > glowSize) {
			return vec4(0, 0, 0, 0);
		} else if (closestDist <= borderSize + 0.5) {
			return borderColour;
		}
		number ratio = (closestDist - borderSize)/glowSize;
		
		number r = outerColour[0]*ratio + innerColour[0]*(1 - ratio);
		number g = outerColour[1]*ratio + innerColour[1]*(1 - ratio);
		number b = outerColour[2]*ratio + innerColour[2]*(1 - ratio);
		number a = outerColour[3]*ratio + innerColour[3]*(1 - ratio);
		
		//vec4 rPix = Texel(image, texture_coords + vec2(float(17)/love_ScreenSize.x, 0));
		
		return vec4(r, g, b, a);
	}
]]

return Shader
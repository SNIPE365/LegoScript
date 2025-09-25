screenres 800,600,32,,FB.GFX_OPENGL

dim as any ptr fbImg = ImageCreate(800, 600)
' Draw in software
draw string fbImg, (10,10), "Text Overlay", rgb(255,255,255)

' Now upload to GL
dim as GLuint tex
glGenTextures(1, @tex)
glBindTexture(GL_TEXTURE_2D, tex)
glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, 800, 600, 0, GL_BGRA, GL_UNSIGNED_BYTE, fbImg + sizeof(fb.image))

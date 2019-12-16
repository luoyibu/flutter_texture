attribute vec3 position;
uniform float angle;

void main()
{
    float xPos = position.x * cos(angle) - position.y * sin(angle);
    float yPos = position.x * sin(angle) + position.y * cos(angle);
    
    gl_Position = vec4(xPos, yPos, position.z, 1.0);
}

y += y_speed;
alpha -= 1 / lifetime;

if (alpha <= 0)
    instance_destroy();
#include <stdbool.h>

volatile int pixel_buffer_start; // global variable

// Function declarations
int abs(int x);
void swap(int *x, int *y);
void clear_screen();
void draw_line(int x0, int y0, int x1, int y1, short int color);
void plot_pixel(int x, int y, short int line_color);

int main(void)
{
    volatile int *pixel_ctrl_ptr = (int *) 0xFF203020;
    /* Read location of the pixel buffer from the pixel buffer controller */
    pixel_buffer_start = *pixel_ctrl_ptr;
    bool going_down = true;     // Whether the line is going down
    int y = 0;                  // y position of line
    int y_min = 0;              // Min y coordinate
    int y_max = 239;            // Max y coordinate
    short int color = 0x07E0;   // Color of line (Green)

    while (true) {
        draw_line(0, y, 319, y, 0x0);   // Clear the previous line
        if (going_down && y == y_max)   // Start going up if at bottom
            going_down = false;
        else if (!going_down && y == y_min) // Start going down if at top
            going_down = true;

        // Update position of line
        int delta_y = going_down ? 1 : -1;
        y += delta_y;

        // Draw the new line
        draw_line(0, y, 319, y, color);

        // Wait for vsync
        *pixel_ctrl_ptr = 1;
        while ((*(pixel_ctrl_ptr + 3) & 1) == 1);
    }
}

int abs(int x) {
    if (x < 0)
        return -1 * x;
    else
        return x;
}

void swap(int *x, int *y) {
    int temp = *x;
    *x = *y;
    *y = temp;
}

void clear_screen() {
    // Just plot a black pixel on every pixel of the screen
    // to clear the contents of the screen
    int x_max = 320;
    int y_max = 240;
    int x, y;
    short int black = 0;
    for (x = 0; x < x_max; ++x) {
        for (y = 0; y < y_max; ++y) {
            plot_pixel(x, y, black);
        }
    }
}

void draw_line(int x0, int y0, int x1, int y1, short int color) {
    // This is just the algorithm they gave us
    bool is_steep = abs(y1 - y0) > abs(x1 - x0);
    if (is_steep) {
        swap(&x0, &y0);
        swap(&x1, &y1);
    }
    if (x0 > x1) {
        swap(&x0, &x1);
        swap(&y0, &y1);
    }
    int deltax = x1 - x0;
    int deltay = abs(y1 - y0);
    int error = -(deltax / 2);
    int y = y0;
    int y_step;
    if (y0 < y1)
        y_step = 1;
    else
        y_step = -1;

    int x;
    for (x = x0; x <= x1; ++x) {
        if (is_steep)
            plot_pixel(y, x, color);
        else
            plot_pixel(x, y, color);
        error = error + deltay;
        if (error >= 0) {
            y = y + y_step;
            error = error - deltax;
        }
    }

}

void plot_pixel(int x, int y, short int line_color)
{
    *(short int *)(pixel_buffer_start + (y << 10) + (x << 1)) = line_color;
}

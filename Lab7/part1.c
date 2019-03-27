#include <stdbool.h>

// Function declarations
int abs(int x);
void swap(int *x, int *y);
void clear_screen();
void draw_line(int x0, int y0, int x1, int y1, short int color);
void plot_pixel(int x, int y, short int line_color);

volatile int pixel_buffer_start; // global variable

int main(void)
{
    volatile int *pixel_ctrl_ptr = (int *) 0xFF203020;
    /* Read location of the pixel buffer from the pixel buffer controller */
    pixel_buffer_start = *pixel_ctrl_ptr;
    clear_screen();
    draw_line(0, 0, 150, 150, 0x001F);   // this line is blue
    draw_line(150, 150, 319, 0, 0x07E0); // this line is green
    draw_line(0, 239, 319, 239, 0xF800); // this line is red
    draw_line(319, 0, 0, 239, 0xF81F);   // this line is a pink color
    while (true);	// Should loop forever at end of program
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

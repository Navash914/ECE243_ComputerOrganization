#include <stdbool.h>
#include <stdlib.h>
//#include <time.h>

// Struct to represent each rectangle
typedef struct rect {
    int x, y;           // Coordinate of rectangle position
    int width, height;  // Dimensions of rectangle
    bool down, right;   // Direction of movement of rectangle
    int speed;
    short int color;    // Color of rectangle
} Rectangle;

// Function declarations
int abs(int x);
void swap(int *x, int *y);
void clear_screen();
void draw_line(int x0, int y0, int x1, int y1, short int color);
void plot_pixel(int x, int y, short int line_color);
void wait_for_vsync();

// global variables
volatile int pixel_buffer_start; 
volatile int * pixel_ctrl_ptr = (int *)0xFF203020;

int main(void)
{
    int x_min = 0, y_min = 0;
    int x_max = 320, y_max = 240;

    int SIZE = 8;   // Number of rectangles on screen

    // Seed the random number generator
    // Not sure why it was giving an error. Will try fixing later
    //time_t t;
    //srand((unsigned) time(&t));

    // initialize location and direction of rectangles
    Rectangle rects[SIZE];
    int i;
    for (i = 0; i < SIZE; ++i) {
        rects[i].width = 2;
        rects[i].height = rects[i].width;

        // Randomize starting point
        rects[i].x = rand() % (x_max - rects[i].width);
        rects[i].y = rand() % (y_max - rects[i].height);

        // Randomize starting direction
        rects[i].down = (bool) (rand() % 2);
        rects[i].right = (bool) (rand() % 2);

        // Randomize starting speed
        rects[i].speed = 1 + rand() % 4;

        // Randomize starting color
        rects[i].color = rand() % 0xFFFF;
    }

    // Set up double buffer on VGA:

    /* set front pixel buffer to start of FPGA On-chip memory */
    *(pixel_ctrl_ptr + 1) = 0xC8000000; // first store the address in the 
                                        // back buffer
    /* now, swap the front/back buffers, to set the front buffer location */
    wait_for_vsync();
    /* initialize a pointer to the pixel buffer, used by drawing functions */
    pixel_buffer_start = *pixel_ctrl_ptr;
    clear_screen(); // pixel_buffer_start points to the pixel buffer
    /* set back pixel buffer to start of SDRAM memory */
    *(pixel_ctrl_ptr + 1) = 0xC0000000;
    pixel_buffer_start = *(pixel_ctrl_ptr + 1); // we draw on the back buffer

    // Double buffer setup complete

    while (true)
    {
        /* Erase any boxes and lines that were drawn in the last iteration */
        clear_screen();

        int j, k;

        // Drawing the rects and lines
        for (i = 0; i <= SIZE; ++i) {
            Rectangle rect = rects[i % SIZE];

            // Draw the rectangle
            if (i < SIZE) {
                for (j = 0; j < rect.width; ++j) {
                    for (k = 0; k < rect.height; ++k) {
                        plot_pixel(rect.x + j, rect.y + k, rect.color);
                    }
                }
            }

            // Draw the connecting line between previous and current rectangle
            if (i > 0) {
                Rectangle prev_rect = rects[i-1];
                int x0 = prev_rect.x, y0 = prev_rect.y;
                int x1 = rect.x, y1 = rect.y;
                short int color = prev_rect.color;
                draw_line(x0, y0, x1, y1, color);
            }
        }

        // Update rectangle positions
        for (i = 0; i < SIZE; ++i) {
            Rectangle* rect = &rects[i];    // use pointer to not create a copy

            if ((rect->right && rect->x + rect->width >= x_max) || (!rect->right && rect->x <= x_min)) {
                // Rectangle hit a horizontal boundary
                rect->right = !rect->right;     // Reverse horizontal direction
                rect->color = rand() % 0xFFFF;  // Randomize color
                rect->speed = 1 + rand() % 4;  // Randomize speed
            }
            if ((rect->down && rect->y + rect->height >= y_max) || (!rect->down && rect->y <= y_min)) {
                // Rectangle hit a vertical boundary
                rect->down = !rect->down;       // Reverse vertical direction
                rect->color = rand() % 0xFFFF;  // Randomize color
                rect->speed = 1 + rand() % 4;  // Randomize speed
            }

            // Direction to move rectangle
            int delta_x = rect->right ? 1 : -1;
            int delta_y = rect->down ? 1 : -1;

            // Update rectangle coordinates
            rect->x += delta_x * rect->speed;
            rect->y += delta_y * rect->speed;
        }

        wait_for_vsync(); // swap front and back buffers on VGA vertical sync
        pixel_buffer_start = *(pixel_ctrl_ptr + 1); // new back buffer
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

// code not shown for clear_screen() and draw_line() subroutines
void clear_screen() {
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
    bool is_steep;
    if (abs(y1 - y0) > abs(x1 - x0))
        is_steep = true;
    else
        is_steep = false;
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

void wait_for_vsync() {
    *pixel_ctrl_ptr = 1;
    while ((*(pixel_ctrl_ptr + 3) & 1) == 1);
}

void plot_pixel(int x, int y, short int line_color)
{
    if (x < 0 || x >= 320 || y < 0 || y >= 240)
        return;
    *(short int *)(pixel_buffer_start + (y << 10) + (x << 1)) = line_color;
}
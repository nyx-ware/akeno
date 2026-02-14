void kernel_main()
{
    const char message[] = "Hello from a C kernel in 32-bit protected mode!";
    volatile char* vidmem = (volatile char*)0xb8000;

    for (int i = 0; i < 80 * 25; i++)
    {
        if (i < sizeof(message))
            vidmem[i * 2] = message[i];
        else
            vidmem[i * 2] = ' ';

        vidmem[i * 2 + 1] = 0x0f;
    }

    while (1);
}
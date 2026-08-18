#include <cstdlib>
#include <iostream>
#include <string>

#ifndef APP_VERSION
#define APP_VERSION "unknown"
#endif

#ifndef APP_GIT_REV
#define APP_GIT_REV "unknown"
#endif

int main(int argc, char* argv[])
{
    std::string name = "AutoSD";
    if (argc > 1)
        name = argv[1];

    std::cout << "Hello from " << name << "!\n";
    std::cout << "Version: " << APP_VERSION << " (" << APP_GIT_REV << ")\n";
    return EXIT_SUCCESS;
}

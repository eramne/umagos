#pragma once
#include "FreeImagePlus.h"

class ImageTools {
  public:
    ImageTools();

    // static FIBITMAP* readImage(const char* file, int flag FI_DEFAULT(0));
    // static bool writeImage(FIBITMAP* image, const char* file, int flag FI_DEFAULT(0));
    static bool convertImage(const char* inputFile, const char* outputFile);
};

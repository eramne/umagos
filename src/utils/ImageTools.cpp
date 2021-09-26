#include "ImageTools.h"

ImageTools::ImageTools() {}

// pretty much just copied and pasted from the FreeImage docs, just renamed some variables to make it easier to read
FIBITMAP* ImageTools::readImage(const char* file, int flag) {
    FREE_IMAGE_FORMAT format = FIF_UNKNOWN;
    // check the file format
    format = FreeImage_GetFileType(file, 0);
    if (format == FIF_UNKNOWN) {
        format = FreeImage_GetFIFFromFilename(file);
    }
    // read the image
    if ((format != FIF_UNKNOWN) && FreeImage_FIFSupportsReading(format)) {
        return FreeImage_Load(format, file, flag);
    }
    // null if the file couldn't be read
    return NULL;
}

bool ImageTools::writeImage(FIBITMAP* bitmap, const char* file, int flag) {
    FREE_IMAGE_FORMAT format = FIF_UNKNOWN;
    bool success = false;
    // Try to guess the file format from the file extension
    format = FreeImage_GetFIFFromFilename(file);
    if (format != FIF_UNKNOWN) {
        // Check that the image can be saved in this format
        bool canSave;
        FREE_IMAGE_TYPE image_type = FreeImage_GetImageType(bitmap);
        if (image_type == FIT_BITMAP) {
            int depth = FreeImage_GetBPP(bitmap); // bit depth of the image
            canSave = (FreeImage_FIFSupportsWriting(format) &&
                       FreeImage_FIFSupportsExportBPP(format, depth));
        } else {
            // unknown type
            canSave = FreeImage_FIFSupportsExportType(format, image_type);
        }
        if (canSave) {
            success = FreeImage_Save(format, bitmap, file, flag);
        }
    }
    return success;
}

bool ImageTools::convertImage(const char* inputFile, const char* outputFile) {
    FIBITMAP* bitmap = readImage(inputFile);
    return writeImage(bitmap, outputFile);
}

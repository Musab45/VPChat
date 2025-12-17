using Microsoft.Extensions.Configuration;
using VPChat.Core.Models;

namespace VPChat.Core.Services;

public class FileService : IFileService
{
    private readonly string _uploadPath;
    private readonly string _baseUrl;
    
    // File size limits (in bytes)
    private const long MAX_IMAGE_SIZE = 5 * 1024 * 1024;      // 5 MB
    private const long MAX_AUDIO_SIZE = 10 * 1024 * 1024;     // 10 MB
    private const long MAX_VIDEO_SIZE = 50 * 1024 * 1024;     // 50 MB
    private const long MAX_FILE_SIZE = 20 * 1024 * 1024;      // 20 MB
    
    // Allowed file types
    private static readonly string[] ALLOWED_IMAGE_TYPES = { "image/jpeg", "image/png", "image/gif", "image/webp" };
    private static readonly string[] ALLOWED_AUDIO_TYPES = { "audio/mpeg", "audio/mp3", "audio/wav", "audio/ogg", "audio/webm", "audio/mp4", "audio/x-m4a", "audio/aac", "audio/m4a" };
    private static readonly string[] ALLOWED_VIDEO_TYPES = { "video/mp4", "video/webm", "video/ogg" };
    private static readonly string[] ALLOWED_FILE_TYPES = { 
        "application/pdf", 
        "application/msword", 
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "application/vnd.ms-excel",
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "text/plain",
        "application/zip"
    };

    public FileService(IConfiguration configuration)
    {
        _uploadPath = configuration["FileUpload:Path"] ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads");
        _baseUrl = configuration["FileUpload:BaseUrl"] ?? "http://localhost:5014/uploads";
        
        // Create upload directory if it doesn't exist
        Directory.CreateDirectory(_uploadPath);
        
        // Create subdirectories for different file types
        Directory.CreateDirectory(Path.Combine(_uploadPath, "images"));
        Directory.CreateDirectory(Path.Combine(_uploadPath, "audio"));
        Directory.CreateDirectory(Path.Combine(_uploadPath, "videos"));
        Directory.CreateDirectory(Path.Combine(_uploadPath, "files"));
    }

    public async Task<(string fileUrl, string fileName, long fileSize)> SaveFileAsync(
        Stream fileStream, 
        string fileName, 
        string contentType)
    {
        // Generate unique filename
        var extension = GetFileExtension(fileName);
        var uniqueFileName = $"{Guid.NewGuid()}{extension}";
        
        // Determine subdirectory based on content type
        var subDirectory = GetSubDirectory(contentType);
        var fullPath = Path.Combine(_uploadPath, subDirectory, uniqueFileName);
        
        // Save file
        using (var fileStreamOutput = new FileStream(fullPath, FileMode.Create))
        {
            await fileStream.CopyToAsync(fileStreamOutput);
        }
        
        // Get file size
        var fileInfo = new FileInfo(fullPath);
        var fileSize = fileInfo.Length;
        
        // Generate URL
        var fileUrl = $"{_baseUrl}/{subDirectory}/{uniqueFileName}";
        
        return (fileUrl, fileName, fileSize);
    }

    public Task<bool> DeleteFileAsync(string fileUrl)
    {
        try
        {
            // Extract filename from URL
            var uri = new Uri(fileUrl);
            var relativePath = uri.AbsolutePath.Replace("/uploads/", "");
            var fullPath = Path.Combine(_uploadPath, relativePath);
            
            if (File.Exists(fullPath))
            {
                File.Delete(fullPath);
                return Task.FromResult(true);
            }
            
            return Task.FromResult(false);
        }
        catch
        {
            return Task.FromResult(false);
        }
    }

    public Task<Stream> GetFileAsync(string fileUrl)
    {
        var uri = new Uri(fileUrl);
        var relativePath = uri.AbsolutePath.Replace("/uploads/", "");
        var fullPath = Path.Combine(_uploadPath, relativePath);
        
        if (File.Exists(fullPath))
        {
            return Task.FromResult<Stream>(File.OpenRead(fullPath));
        }
        
        throw new FileNotFoundException("File not found", fullPath);
    }

    public string GetFileExtension(string fileName)
    {
        return Path.GetExtension(fileName).ToLowerInvariant();
    }

    public bool IsValidFileType(string contentType, MessageType messageType)
    {
        return messageType switch
        {
            MessageType.Image => ALLOWED_IMAGE_TYPES.Contains(contentType.ToLower()),
            MessageType.Audio => ALLOWED_AUDIO_TYPES.Contains(contentType.ToLower()),
            MessageType.Video => ALLOWED_VIDEO_TYPES.Contains(contentType.ToLower()),
            MessageType.File => ALLOWED_FILE_TYPES.Contains(contentType.ToLower()),
            _ => false
        };
    }

    public long GetMaxFileSize(MessageType messageType)
    {
        return messageType switch
        {
            MessageType.Image => MAX_IMAGE_SIZE,
            MessageType.Audio => MAX_AUDIO_SIZE,
            MessageType.Video => MAX_VIDEO_SIZE,
            MessageType.File => MAX_FILE_SIZE,
            _ => 0
        };
    }

    private string GetSubDirectory(string contentType)
    {
        if (ALLOWED_IMAGE_TYPES.Contains(contentType.ToLower()))
            return "images";
        if (ALLOWED_AUDIO_TYPES.Contains(contentType.ToLower()))
            return "audio";
        if (ALLOWED_VIDEO_TYPES.Contains(contentType.ToLower()))
            return "videos";
        
        return "files";
    }
}

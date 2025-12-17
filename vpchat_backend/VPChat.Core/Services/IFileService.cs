namespace VPChat.Core.Services;

public interface IFileService
{
    /// <summary>
    /// Saves a file to storage and returns its URL, filename, and size
    /// </summary>
    Task<(string fileUrl, string fileName, long fileSize)> SaveFileAsync(
        Stream fileStream, 
        string fileName, 
        string contentType);
    
    /// <summary>
    /// Deletes a file from storage
    /// </summary>
    Task<bool> DeleteFileAsync(string fileUrl);
    
    /// <summary>
    /// Gets a file stream from storage
    /// </summary>
    Task<Stream> GetFileAsync(string fileUrl);
    
    /// <summary>
    /// Gets the file extension from filename
    /// </summary>
    string GetFileExtension(string fileName);
    
    /// <summary>
    /// Validates if file type is allowed for the message type
    /// </summary>
    bool IsValidFileType(string contentType, Models.MessageType messageType);
    
    /// <summary>
    /// Gets the maximum allowed file size for a message type
    /// </summary>
    long GetMaxFileSize(Models.MessageType messageType);
}

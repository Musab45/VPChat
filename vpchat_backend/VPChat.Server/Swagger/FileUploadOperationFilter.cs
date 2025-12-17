using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;

namespace VPChat.Server.Swagger
{
    public class FileUploadOperationFilter : IOperationFilter
    {
        public void Apply(OpenApiOperation operation, OperationFilterContext context)
        {
            // Check if this is a file upload endpoint
            var fileParams = context.ApiDescription.ParameterDescriptions
                .Where(p => p.Type == typeof(IFormFile) ||
                           p.Type == typeof(IEnumerable<IFormFile>))
                .ToList();

            if (!fileParams.Any())
                return;

            // Clear existing parameters to avoid conflicts
            operation.Parameters.Clear();

            // Build multipart/form-data schema
            var properties = new Dictionary<string, OpenApiSchema>();
            
            // Add file parameter
            properties["file"] = new OpenApiSchema
            {
                Type = "string",
                Format = "binary",
                Description = "The file to upload"
            };

            // Add other form parameters
            foreach (var param in context.ApiDescription.ParameterDescriptions
                .Where(p => p.Type != typeof(IFormFile) && 
                           p.Source?.Id == "Form"))
            {
                properties[param.Name] = new OpenApiSchema
                {
                    Type = param.Type == typeof(int) ? "integer" : "string",
                    Description = param.Name
                };
            }

            operation.RequestBody = new OpenApiRequestBody
            {
                Required = true,
                Content = new Dictionary<string, OpenApiMediaType>
                {
                    ["multipart/form-data"] = new OpenApiMediaType
                    {
                        Schema = new OpenApiSchema
                        {
                            Type = "object",
                            Properties = properties,
                            Required = new HashSet<string> { "file", "messageType" }
                        }
                    }
                }
            };
        }
    }
}

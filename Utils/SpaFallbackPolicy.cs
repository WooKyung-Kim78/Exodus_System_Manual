using Microsoft.AspNetCore.Http;

namespace ExodusSystemManual.Utils;

public static class SpaFallbackPolicy
{
    public static bool ShouldServe(HttpRequest request, bool isDevelopment)
    {
        var path = request.Path;
        return HttpMethods.IsGet(request.Method)
            && !path.StartsWithSegments("/api")
            && !path.StartsWithSegments("/Upload")
            && !Path.HasExtension(path.Value)
            && (isDevelopment || !path.StartsWithSegments("/dev/styleguide"));
    }
}

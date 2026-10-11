using System.Collections.Specialized;

namespace PBScreenshot.Native.Clipboard;

public static class FileClipboard
{
    public static void Copy(string path)
    {
        if (!File.Exists(path)) throw new FileNotFoundException("Capture file does not exist.", path);
        var data = new DataObject();
        data.SetFileDropList(new StringCollection { Path.GetFullPath(path) });
        System.Windows.Forms.Clipboard.SetDataObject(data, true, 10, 100);
    }
}

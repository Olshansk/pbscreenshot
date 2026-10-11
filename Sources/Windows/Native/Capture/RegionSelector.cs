namespace PBScreenshot.Native.Capture;

public sealed class RegionSelector : Form
{
    private Point start;
    private bool dragging;
    public Rectangle Selection { get; private set; }

    public RegionSelector()
    {
        FormBorderStyle = FormBorderStyle.None;
        StartPosition = FormStartPosition.Manual;
        Bounds = SystemInformation.VirtualScreen;
        TopMost = true;
        ShowInTaskbar = false;
        DoubleBuffered = true;
        BackColor = Color.Black;
        Opacity = 0.25;
        Cursor = Cursors.Cross;
        KeyPreview = true;
        AccessibleName = "Select screenshot area. Drag to select; Escape to cancel.";
        KeyDown += (_, e) => { if (e.KeyCode == Keys.Escape) { DialogResult = DialogResult.Cancel; Close(); } };
        MouseDown += (_, e) => { if (e.Button == MouseButtons.Left) { start = e.Location; dragging = true; Capture = true; } };
        MouseMove += (_, e) => { if (dragging) { Selection = Rectangle.FromLTRB(Math.Min(start.X, e.X), Math.Min(start.Y, e.Y), Math.Max(start.X, e.X), Math.Max(start.Y, e.Y)); Invalidate(); } };
        MouseUp += (_, e) =>
        {
            if (!dragging || e.Button != MouseButtons.Left) return;
            Selection = Rectangle.FromLTRB(Math.Min(start.X, e.X), Math.Min(start.Y, e.Y), Math.Max(start.X, e.X), Math.Max(start.Y, e.Y));
            Selection = new Rectangle(PointToScreen(Selection.Location), Selection.Size);
            DialogResult = Selection.Width > 0 && Selection.Height > 0 ? DialogResult.OK : DialogResult.Cancel;
            Close();
        };
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        base.OnPaint(e);
        using var pen = new Pen(Color.White, 3);
        if (dragging) e.Graphics.DrawRectangle(pen, Selection);
    }
}

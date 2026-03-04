import { useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Sparkles, Upload, WandSparkles } from "lucide-react";
import { toast } from "@/components/ui/sonner";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Badge } from "@/components/ui/badge";
import { api } from "@/services/api";

export default function DashboardPage() {
  const navigate = useNavigate();
  const [filename, setFilename] = useState("sample.py");
  const [language, setLanguage] = useState("python");
  const [code, setCode] = useState("");
  const [loading, setLoading] = useState(false);
  const [report, setReport] = useState(null);

  const counts = useMemo(() => {
    if (!report) return { critical: 0, high: 0, total: 0 };
    return {
      critical: report.issues.filter((issue) => issue.severity === "critical").length,
      high: report.issues.filter((issue) => issue.severity === "high").length,
      total: report.issues.length,
    };
  }, [report]);

  const onUpload = async (event) => {
    const file = event.target.files?.[0];
    if (!file) return;
    const text = await file.text();
    setCode(text);
    setFilename(file.name);
    toast.success("Code file loaded");
  };

  const runAnalysis = async () => {
    if (!code.trim()) {
      toast.error("Add code before running analysis.");
      return;
    }
    setLoading(true);
    try {
      const data = await api.analyzeCode({ code, filename, language });
      setReport(data);
      toast.success("Analysis completed");
    } catch (error) {
      toast.error(error?.response?.data?.detail || "Failed to analyze code");
    } finally {
      setLoading(false);
    }
  };

  return (
    <section className="space-y-6" data-testid="dashboard-page">
      <div className="rounded-xl border border-border bg-card/70 p-6 backdrop-blur-xl" data-testid="dashboard-header-card">
        <h2 className="text-4xl font-bold tracking-tight" data-testid="dashboard-heading">Code Health Command Center</h2>
        <p className="mt-2 text-base text-muted-foreground" data-testid="dashboard-description">
          Detect slop, get repair snippets, and generate maintainable docs in one pass.
        </p>
      </div>

      <div className="grid grid-cols-1 gap-6 xl:grid-cols-12">
        <Card className="xl:col-span-7" data-testid="code-input-card">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-xl" data-testid="code-input-title">
              <Sparkles className="h-5 w-5 text-primary" /> Analyze Source Code
            </CardTitle>
            <CardDescription data-testid="code-input-description">Paste or upload code to run slop detection and fix generation.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
              <Input data-testid="filename-input" value={filename} onChange={(e) => setFilename(e.target.value)} placeholder="Filename" className="h-10" />
              <select
                data-testid="language-select"
                className="h-10 rounded-md border border-input bg-background px-3 text-sm"
                value={language}
                onChange={(e) => setLanguage(e.target.value)}
              >
                <option value="python">Python</option>
                <option value="javascript">JavaScript</option>
                <option value="typescript">TypeScript</option>
              </select>
            </div>

            <Textarea
              data-testid="code-textarea"
              value={code}
              onChange={(e) => setCode(e.target.value)}
              className="min-h-[340px] font-mono text-sm"
              placeholder="Paste your code here..."
            />

            <div className="flex flex-wrap gap-3">
              <label className="inline-flex cursor-pointer items-center gap-2 rounded-md border border-border bg-background px-4 py-2 text-sm hover:border-primary/40" data-testid="upload-code-label">
                <Upload className="h-4 w-4" /> Upload File
                <input data-testid="upload-code-input" type="file" className="hidden" onChange={onUpload} />
              </label>
              <Button data-testid="run-analysis-button" className="h-10" onClick={runAnalysis} disabled={loading}>
                {loading ? "Analyzing..." : "Run Doctor"}
              </Button>
            </div>
          </CardContent>
        </Card>

        <div className="space-y-6 xl:col-span-5">
          <Card data-testid="result-summary-card">
            <CardHeader>
              <CardTitle className="text-xl" data-testid="result-summary-title">Current Report Snapshot</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-3 gap-3">
                <div className="rounded-lg border border-border bg-background p-3" data-testid="metric-total-issues">
                  <p className="text-xs text-muted-foreground">Total</p>
                  <p className="text-xl font-semibold">{counts.total}</p>
                </div>
                <div className="rounded-lg border border-border bg-background p-3" data-testid="metric-high-issues">
                  <p className="text-xs text-muted-foreground">High</p>
                  <p className="text-xl font-semibold">{counts.high}</p>
                </div>
                <div className="rounded-lg border border-border bg-background p-3" data-testid="metric-critical-issues">
                  <p className="text-xs text-muted-foreground">Critical</p>
                  <p className="text-xl font-semibold">{counts.critical}</p>
                </div>
              </div>

              {report ? (
                <div className="space-y-3" data-testid="latest-analysis-preview">
                  <p className="text-sm text-muted-foreground">{report.summary}</p>
                  <div className="flex flex-wrap gap-2">
                    <Badge variant="secondary" data-testid="analysis-mode-badge">{report.mode}</Badge>
                    <Badge variant="outline" data-testid="analysis-language-badge">{report.language}</Badge>
                  </div>
                  <Button data-testid="open-report-details-button" className="h-10 w-full" variant="outline" onClick={() => navigate(`/reports/${report.report_id}`)}>
                    <WandSparkles className="h-4 w-4" /> Open Full Report
                  </Button>
                </div>
              ) : (
                <p className="text-sm text-muted-foreground" data-testid="no-analysis-text">Run your first analysis to view issue breakdown and generated docs.</p>
              )}
            </CardContent>
          </Card>
        </div>
      </div>
    </section>
  );
}
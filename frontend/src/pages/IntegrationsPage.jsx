import { useEffect, useState } from "react";
import { toast } from "@/components/ui/sonner";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { api } from "@/services/api";

export default function IntegrationsPage() {
  const [events, setEvents] = useState([]);
  const [gitPayload, setGitPayload] = useState({ repository: "repo/sample", event_type: "push", branch: "main", commit_sha: "abc123" });
  const [ciPayload, setCiPayload] = useState({ pipeline: "test-suite", status: "passed", branch: "main", commit_sha: "abc123" });

  const loadEvents = async () => {
    const data = await api.getIntegrationEvents();
    setEvents(data);
  };

  useEffect(() => {
    loadEvents();
  }, []);

  const sendGitEvent = async () => {
    await api.sendGitWebhook(gitPayload);
    toast.success("Git webhook event accepted");
    loadEvents();
  };

  const sendCiEvent = async () => {
    await api.sendCiEvent(ciPayload);
    toast.success("CI pipeline event accepted");
    loadEvents();
  };

  return (
    <section className="space-y-6" data-testid="integrations-page">
      <div className="rounded-xl border border-border bg-card/70 p-6" data-testid="integrations-header-card">
        <h2 className="text-4xl font-bold tracking-tight" data-testid="integrations-heading">Integration Stubs</h2>
        <p className="mt-2 text-base text-muted-foreground" data-testid="integrations-subheading">Send test events for Git and CI workflows before full production hooks.</p>
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <Card data-testid="git-webhook-card">
          <CardHeader><CardTitle data-testid="git-webhook-title">Git Webhook Stub</CardTitle></CardHeader>
          <CardContent className="space-y-3">
            <Input data-testid="git-repository-input" className="h-10" value={gitPayload.repository} onChange={(e) => setGitPayload({ ...gitPayload, repository: e.target.value })} placeholder="Repository" />
            <Input data-testid="git-event-type-input" className="h-10" value={gitPayload.event_type} onChange={(e) => setGitPayload({ ...gitPayload, event_type: e.target.value })} placeholder="Event type" />
            <Input data-testid="git-branch-input" className="h-10" value={gitPayload.branch} onChange={(e) => setGitPayload({ ...gitPayload, branch: e.target.value })} placeholder="Branch" />
            <Input data-testid="git-commit-input" className="h-10" value={gitPayload.commit_sha} onChange={(e) => setGitPayload({ ...gitPayload, commit_sha: e.target.value })} placeholder="Commit SHA" />
            <Button data-testid="send-git-event-button" className="h-10" onClick={sendGitEvent}>Send Git Event</Button>
          </CardContent>
        </Card>

        <Card data-testid="ci-event-card">
          <CardHeader><CardTitle data-testid="ci-event-title">CI Event Stub</CardTitle></CardHeader>
          <CardContent className="space-y-3">
            <Input data-testid="ci-pipeline-input" className="h-10" value={ciPayload.pipeline} onChange={(e) => setCiPayload({ ...ciPayload, pipeline: e.target.value })} placeholder="Pipeline" />
            <Input data-testid="ci-status-input" className="h-10" value={ciPayload.status} onChange={(e) => setCiPayload({ ...ciPayload, status: e.target.value })} placeholder="Status" />
            <Input data-testid="ci-branch-input" className="h-10" value={ciPayload.branch} onChange={(e) => setCiPayload({ ...ciPayload, branch: e.target.value })} placeholder="Branch" />
            <Input data-testid="ci-commit-input" className="h-10" value={ciPayload.commit_sha} onChange={(e) => setCiPayload({ ...ciPayload, commit_sha: e.target.value })} placeholder="Commit SHA" />
            <Button data-testid="send-ci-event-button" className="h-10" variant="secondary" onClick={sendCiEvent}>Send CI Event</Button>
          </CardContent>
        </Card>
      </div>

      <Card data-testid="integration-events-card">
        <CardHeader><CardTitle data-testid="integration-events-title">Recent Integration Events</CardTitle></CardHeader>
        <CardContent className="space-y-3" data-testid="integration-events-list">
          {events.length === 0 ? (
            <p className="text-sm text-muted-foreground" data-testid="integration-events-empty">No events received yet.</p>
          ) : (
            events.map((event) => (
              <div key={event.event_id} className="rounded-lg border border-border bg-background p-3 text-sm" data-testid={`integration-event-${event.event_id}`}>
                <p className="font-medium" data-testid={`integration-event-source-${event.event_id}`}>{event.source} · {event.event_type}</p>
                <p className="text-muted-foreground" data-testid={`integration-event-status-${event.event_id}`}>{event.status}</p>
              </div>
            ))
          )}
        </CardContent>
      </Card>
    </section>
  );
}
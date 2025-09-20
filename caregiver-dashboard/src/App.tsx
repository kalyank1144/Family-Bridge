import { useEffect, useMemo, useState } from "react";
import {
  Tabs,
  TabsContent,
  TabsList,
  TabsTrigger,
} from "@/components/ui/tabs";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Separator } from "@/components/ui/separator";
import {
  AlertTriangle,
  Bell,
  CalendarDays,
  CheckCircle2,
  ChevronDown,
  ChevronRight,
  Cloud,
  CloudOff,
  Download,
  FileText,
  HeartPulse,
  LineChart as LineChartIcon,
  LockKeyhole,
  Phone,
  Pill,
  Settings,
  Share2,
  Shield,
  Stethoscope,
  Upload,
  Users,
  Link as LinkIcon,
} from "lucide-react";
import {
  ResponsiveContainer,
  LineChart,
  Line,
  CartesianGrid,
  XAxis,
  YAxis,
  Tooltip,
  AreaChart,
  Area,
  BarChart,
  Bar,
} from "recharts";
import { format, addDays, startOfMonth, endOfMonth, isSameDay, isWithinInterval } from "date-fns";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Switch } from "@/components/ui/switch";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { cn } from "@/lib/utils";

type VitalSample = { date: string; hr: number; sys: number; dia: number; steps: number; sleep: number };

type Appointment = {
  id: string;
  memberId: string;
  title: string;
  doctor: string;
  type: string;
  date: string;
  time: string;
  location: string;
  notes?: string;
};

type Alert = {
  id: string;
  memberId?: string;
  title: string;
  severity: "critical" | "high" | "medium" | "low";
  time: string;
  acknowledged: boolean;
};

type CareGoal = { id: string; title: string; target: string; progress: number; owner: string };

type Member = {
  id: string;
  name: string;
  relation: string;
  age: number;
  photo?: string;
  status: "stable" | "attention" | "urgent";
  medicationCompliance: number;
  mood7d: number[];
  vitals: VitalSample[];
  goals: CareGoal[];
};

const seedVitals = (days = 30) => {
  const out: VitalSample[] = [];
  for (let i = days - 1; i >= 0; i--) {
    const d = addDays(new Date(), -i);
    const hr = 60 + Math.round(Math.random() * 25);
    const sys = 110 + Math.round(Math.random() * 25);
    const dia = 70 + Math.round(Math.random() * 15);
    const steps = 2000 + Math.round(Math.random() * 6000);
    const sleep = 5 + Math.round(Math.random() * 4);
    out.push({ date: d.toISOString(), hr, sys, dia, steps, sleep });
  }
  return out;
};

const membersSeed: Member[] = [
  {
    id: "m1",
    name: "Evelyn Harper",
    relation: "Mother",
    age: 78,
    status: "stable",
    medicationCompliance: 92,
    mood7d: [4, 4, 5, 3, 4, 4, 5],
    vitals: seedVitals(),
    goals: [
      { id: "g1", title: "Morning Walk", target: "5,000 steps/day", progress: 70, owner: "Jane" },
      { id: "g2", title: "Hydration", target: "6 glasses/day", progress: 55, owner: "Family" },
    ],
  },
  {
    id: "m2",
    name: "Robert Harper",
    relation: "Father",
    age: 81,
    status: "attention",
    medicationCompliance: 84,
    mood7d: [3, 3, 4, 2, 3, 3, 4],
    vitals: seedVitals(),
    goals: [
      { id: "g3", title: "BP Monitoring", target: "Daily reading", progress: 62, owner: "Jane" },
    ],
  },
  {
    id: "m3",
    name: "Aunt May",
    relation: "Aunt",
    age: 74,
    status: "stable",
    medicationCompliance: 97,
    mood7d: [5, 4, 5, 5, 4, 5, 5],
    vitals: seedVitals(),
    goals: [
      { id: "g4", title: "PT Exercises", target: "3x per week", progress: 40, owner: "Alex" },
    ],
  },
];

const apptsSeed: Appointment[] = [
  {
    id: "a1",
    memberId: "m1",
    title: "Primary Care Checkup",
    doctor: "Dr. Patel",
    type: "Checkup",
    date: addDays(new Date(), 1).toISOString(),
    time: "10:30 AM",
    location: "Bay Medical Center",
  },
  {
    id: "a2",
    memberId: "m2",
    title: "Cardiology Consult",
    doctor: "Dr. Lin",
    type: "Cardiology",
    date: addDays(new Date(), 3).toISOString(),
    time: "2:00 PM",
    location: "Cardio Clinic",
  },
  {
    id: "a3",
    memberId: "m3",
    title: "Physical Therapy",
    doctor: "Jordan Lee, PT",
    type: "Physical Therapy",
    date: addDays(new Date(), 7).toISOString(),
    time: "9:00 AM",
    location: "MotionWorks",
  },
];

const alertsSeed: Alert[] = [
  { id: "al1", memberId: "m2", title: "Missed morning medication", severity: "high", time: new Date().toISOString(), acknowledged: false },
  { id: "al2", memberId: "m1", title: "Elevated blood pressure trend", severity: "medium", time: addDays(new Date(), -1).toISOString(), acknowledged: false },
  { id: "al3", title: "Daily check-in missed by 1 member", severity: "low", time: addDays(new Date(), -2).toISOString(), acknowledged: true },
];

const severityColor: Record<Alert["severity"], string> = {
  critical: "bg-red-100 text-red-700 border-red-200",
  high: "bg-amber-100 text-amber-800 border-amber-200",
  medium: "bg-yellow-50 text-yellow-800 border-yellow-200",
  low: "bg-slate-50 text-slate-700 border-slate-200",
};

function Stat({ label, value, sub, icon }: { label: string; value: string; sub?: string; icon?: JSX.Element }) {
  return (
    <Card>
      <CardHeader className="flex-row items-center justify-between">
        <CardTitle className="text-base font-medium text-muted-foreground">{label}</CardTitle>
        {icon}
      </CardHeader>
      <CardContent>
        <div className="text-3xl font-semibold tracking-tight">{value}</div>
        {sub && <div className="text-sm text-muted-foreground mt-1">{sub}</div>}
      </CardContent>
    </Card>
  );
}

function SparkLine({ data, dataKey, color }: { data: VitalSample[]; dataKey: keyof VitalSample; color: string }) {
  return (
    <div className="h-16">
      <ResponsiveContainer width="100%" height="100%">
        <LineChart data={data} margin={{ top: 2, right: 4, bottom: 0, left: -10 }}>
          <Line type="monotone" dataKey={dataKey as string} stroke={color} strokeWidth={2} dot={false} />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
}

function MemberCard({ m, onSelect }: { m: Member; onSelect: (id: string) => void }) {
  const statusDot = m.status === "urgent" ? "bg-red-500" : m.status === "attention" ? "bg-amber-500" : "bg-emerald-500";
  const last = m.vitals[m.vitals.length - 1];
  return (
    <Card>
      <CardHeader className="flex-row items-center gap-3">
        <div className={cn("h-2 w-2 rounded-full", statusDot)} />
        <div className="flex-1">
          <CardTitle className="text-lg font-semibold">{m.name}</CardTitle>
          <CardDescription>{m.relation} • {m.age}</CardDescription>
        </div>
        <Button size="sm" variant="outline" onClick={() => onSelect(m.id)}>
          View Health
        </Button>
      </CardHeader>
      <CardContent className="grid grid-cols-2 gap-4">
        <div>
          <div className="text-sm text-muted-foreground">Medication Compliance</div>
          <div className="mt-1 flex items-center gap-2">
            <Progress value={m.medicationCompliance} className="h-2" />
            <div className="text-sm font-medium">{m.medicationCompliance}%</div>
          </div>
          <div className="mt-3 grid grid-cols-3 gap-2 text-xs">
            <div className="rounded-md border p-2">
              <div className="text-muted-foreground">HR</div>
              <div className="font-semibold">{last.hr} bpm</div>
            </div>
            <div className="rounded-md border p-2">
              <div className="text-muted-foreground">BP</div>
              <div className="font-semibold">{last.sys}/{last.dia}</div>
            </div>
            <div className="rounded-md border p-2">
              <div className="text-muted-foreground">Steps</div>
              <div className="font-semibold">{last.steps}</div>
            </div>
          </div>
        </div>
        <div className="space-y-2">
          <SparkLine data={m.vitals.slice(-14)} dataKey="hr" color="#0ea5a8" />
          <div className="flex items-center gap-2">
            <Badge variant="secondary" className="gap-1"><Stethoscope className="h-3 w-3" />Vitals</Badge>
            <Badge variant="secondary" className="gap-1"><Pill className="h-3 w-3" />Meds</Badge>
            <Badge variant="secondary" className="gap-1"><Users className="h-3 w-3" />Care Team</Badge>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

function exportCSV(filename: string, rows: Record<string, string | number>[]) {
  const headers = Object.keys(rows[0] || {});
  const csv = [headers.join(","), ...rows.map((r) => headers.map((h) => `${r[h] ?? ""}`).join(","))].join("\n");
  const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `${filename}.csv`;
  a.click();
  URL.revokeObjectURL(url);
}

export default function App() {
  const [members, setMembers] = useState<Member[]>(() => {
    const cached = localStorage.getItem("fb-members");
    return cached ? JSON.parse(cached) : membersSeed;
  });
  const [appointments, setAppointments] = useState<Appointment[]>(() => {
    const cached = localStorage.getItem("fb-appts");
    return cached ? JSON.parse(cached) : apptsSeed;
  });
  const [alerts, setAlerts] = useState<Alert[]>(() => {
    const cached = localStorage.getItem("fb-alerts");
    return cached ? JSON.parse(cached) : alertsSeed;
  });
  const [selectedMemberId, setSelectedMemberId] = useState<string>(members[0]?.id || "");
  const [offline, setOffline] = useState(false);
  const [activeTab, setActiveTab] = useState("overview");

  useEffect(() => {
    localStorage.setItem("fb-members", JSON.stringify(members));
  }, [members]);
  useEffect(() => {
    localStorage.setItem("fb-appts", JSON.stringify(appointments));
  }, [appointments]);
  useEffect(() => {
    localStorage.setItem("fb-alerts", JSON.stringify(alerts));
  }, [alerts]);

  const selectedMember = members.find((m) => m.id === selectedMemberId) || members[0];

  const monthlyAppts = useMemo(() => {
    const start = startOfMonth(new Date());
    const end = endOfMonth(new Date());
    return appointments.filter((a) => isWithinInterval(new Date(a.date), { start, end }));
  }, [appointments]);

  const criticalCount = alerts.filter((a) => a.severity === "critical" && !a.acknowledged).length;
  const highCount = alerts.filter((a) => a.severity === "high" && !a.acknowledged).length;
  const next7 = useMemo(() => appointments.filter((a) => new Date(a.date) < addDays(new Date(), 7)).sort((a,b) => +new Date(a.date) - +new Date(b.date)), [appointments]);

  const healthTrends = useMemo(() => selectedMember?.vitals.slice(-30) || [], [selectedMember]);

  const addAppointment = (appt: Appointment) => {
    setAppointments((prev) => [...prev, appt]);
  };

  const acknowledgeAlert = (id: string) => setAlerts((prev) => prev.map((a) => a.id === id ? { ...a, acknowledged: true } : a));

  return (
    <div className="min-h-screen bg-gradient-to-b from-background to-background/60">
      <header className="no-print sticky top-0 z-30 border-b bg-background/80 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="container mx-auto flex h-16 items-center justify-between px-4">
          <div className="flex items-center gap-3">
            <div className="h-8 w-8 rounded-lg bg-primary/15 ring-1 ring-primary/30 grid place-items-center">
              <Stethoscope className="h-5 w-5 text-primary" />
            </div>
            <div>
              <div className="text-sm text-muted-foreground">FamilyBridge</div>
              <div className="text-lg font-semibold">Caregiver Command Center</div>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <Button variant="outline" size="sm" onClick={() => window.print()} className="gap-2"><FileText className="h-4 w-4" /> Print</Button>
            <Button variant="outline" size="sm" onClick={() => exportCSV("appointments", appointments.map(a => ({
              date: format(new Date(a.date), 'yyyy-MM-dd'), time: a.time, member: members.find(m=>m.id===a.memberId)?.name || '', title: a.title, doctor: a.doctor, type: a.type, location: a.location
            })))} className="gap-2"><Download className="h-4 w-4" /> Export</Button>
            <Button variant="ghost" size="icon" className="relative">
              <Bell className="h-5 w-5" />
              {(criticalCount + highCount) > 0 && (
                <span className="absolute -right-1 -top-1 grid h-5 min-w-5 place-items-center rounded-full bg-red-500 px-1 text-[10px] font-bold text-white">
                  {criticalCount + highCount}
                </span>
              )}
            </Button>
            <Separator orientation="vertical" className="mx-2 h-6" />
            <div className="flex items-center gap-2 text-sm">
              <Shield className="h-4 w-4 text-emerald-600" />
              <span className="hidden sm:inline">HIPAA-ready</span>
            </div>
            <div className="ml-2 flex items-center gap-2">
              <Cloud className={cn("h-4 w-4", offline ? "text-muted-foreground" : "text-primary")} />
              <Switch checked={offline} onCheckedChange={setOffline} />
              <span className="text-sm">Offline</span>
            </div>
          </div>
        </div>
      </header>

      <main className="container mx-auto px-4 py-6">
        <Tabs value={activeTab} onValueChange={setActiveTab} className="flex min-h-[calc(100vh-6rem)] flex-col">
          <div className="no-print mb-4 flex flex-wrap items-center justify-between gap-3">
            <TabsList className="flex-1">
              <TabsTrigger value="overview">Overview</TabsTrigger>
              <TabsTrigger value="health">Health</TabsTrigger>
              <TabsTrigger value="appointments">Appointments</TabsTrigger>
              <TabsTrigger value="family">Family</TabsTrigger>
              <TabsTrigger value="careplans">Care Plans</TabsTrigger>
              <TabsTrigger value="reports">Reports</TabsTrigger>
              <TabsTrigger value="alerts">Alerts</TabsTrigger>
              <TabsTrigger value="settings">Settings</TabsTrigger>
            </TabsList>
            <div className="flex items-center gap-2">
              <Select value={selectedMember?.id} onValueChange={setSelectedMemberId}>
                <SelectTrigger className="w-[220px]">
                  <SelectValue placeholder="Select member" />
                </SelectTrigger>
                <SelectContent>
                  {members.map((m) => (
                    <SelectItem key={m.id} value={m.id}>{m.name} • {m.relation}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
              <Button className="gap-2" onClick={() => setMembers((prev) => [...prev, { id: `m${prev.length+1}`, name: "New Member", relation: "Relative", age: 70, status: "stable", medicationCompliance: 0, mood7d: [3,3,3,3,3,3,3], vitals: seedVitals(), goals: [] }])}>
                <Users className="h-4 w-4" /> Add Member
              </Button>
            </div>
          </div>

          <TabsContent value="overview" className="space-y-6">
            <div className="grid grid-cols-1 gap-4 md:grid-cols-4">
              <Stat label="Active Alerts" value={`${criticalCount + highCount}`} sub={`${criticalCount} critical, ${highCount} high`} icon={<AlertTriangle className="h-5 w-5 text-amber-600" />} />
              <Stat label="Avg Med Compliance" value={`${Math.round(members.reduce((a,m)=>a+m.medicationCompliance,0)/members.length)}%`} sub="7-day average" icon={<Pill className="h-5 w-5 text-primary" />} />
              <Stat label="Upcoming Appointments" value={`${next7.length}`} sub="Next 7 days" icon={<CalendarDays className="h-5 w-5 text-primary" />} />
              <Stat label="Daily Check-ins" value={`${Math.round(members.reduce((a,m)=>a+m.mood7d.slice(-1)[0],0)/members.length)}/5`} sub="Today average mood" icon={<HeartPulse className="h-5 w-5 text-emerald-600" />} />
            </div>

            <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
              <div className="lg:col-span-2 space-y-4">
                <Card>
                  <CardHeader className="flex-row items-center justify-between">
                    <div>
                      <CardTitle className="text-xl">Family Health Overview</CardTitle>
                      <CardDescription>Key vitals trends for {selectedMember?.name}</CardDescription>
                    </div>
                    <div className="flex items-center gap-2">
                      <Button variant="outline" size="sm" className="gap-2" onClick={() => setActiveTab("health")}>
                        <LineChartIcon className="h-4 w-4" /> View Health
                      </Button>
                    </div>
                  </CardHeader>
                  <CardContent className="grid grid-cols-1 gap-4 md:grid-cols-2">
                    <div className="rounded-xl border p-4">
                      <div className="mb-2 flex items-center justify-between">
                        <div className="text-sm font-medium">Heart Rate</div>
                        <Badge variant="secondary">bpm</Badge>
                      </div>
                      <div className="h-32">
                        <ResponsiveContainer width="100%" height="100%">
                          <LineChart data={healthTrends}>
                            <CartesianGrid strokeDasharray="3 3" stroke="#eee" />
                            <XAxis dataKey="date" hide />
                            <YAxis hide />
                            <Tooltip formatter={(v)=>`${v}`} labelFormatter={(l)=>format(new Date(l), 'MMM d')} />
                            <Line type="monotone" dataKey="hr" stroke="#0ea5a8" strokeWidth={2} dot={false} />
                          </LineChart>
                        </ResponsiveContainer>
                      </div>
                    </div>
                    <div className="rounded-xl border p-4">
                      <div className="mb-2 flex items-center justify-between">
                        <div className="text-sm font-medium">Blood Pressure</div>
                        <Badge variant="secondary">mmHg</Badge>
                      </div>
                      <div className="h-32">
                        <ResponsiveContainer width="100%" height="100%">
                          <AreaChart data={healthTrends}>
                            <CartesianGrid strokeDasharray="3 3" stroke="#eee" />
                            <XAxis dataKey="date" hide />
                            <YAxis hide />
                            <Tooltip formatter={(v)=>`${v}`} labelFormatter={(l)=>format(new Date(l), 'MMM d')} />
                            <Area type="monotone" dataKey="sys" stroke="#60a5fa" fill="#dbeafe" strokeWidth={2} />
                            <Area type="monotone" dataKey="dia" stroke="#4f46e5" fill="#e0e7ff" strokeWidth={2} />
                          </AreaChart>
                        </ResponsiveContainer>
                      </div>
                    </div>
                    <div className="rounded-xl border p-4">
                      <div className="mb-2 flex items-center justify-between">
                        <div className="text-sm font-medium">Daily Steps</div>
                      </div>
                      <div className="h-32">
                        <ResponsiveContainer width="100%" height="100%">
                          <BarChart data={healthTrends}>
                            <XAxis dataKey="date" hide />
                            <YAxis hide />
                            <Tooltip formatter={(v)=>`${v}`} labelFormatter={(l)=>format(new Date(l), 'MMM d')} />
                            <Bar dataKey="steps" fill="#34d399" />
                          </BarChart>
                        </ResponsiveContainer>
                      </div>
                    </div>
                    <div className="rounded-xl border p-4">
                      <div className="mb-2 flex items-center justify-between">
                        <div className="text-sm font-medium">Sleep Hours</div>
                      </div>
                      <div className="h-32">
                        <ResponsiveContainer width="100%" height="100%">
                          <LineChart data={healthTrends}>
                            <XAxis dataKey="date" hide />
                            <YAxis hide />
                            <Tooltip formatter={(v)=>`${v}`} labelFormatter={(l)=>format(new Date(l), 'MMM d')} />
                            <Line type="monotone" dataKey="sleep" stroke="#14b8a6" strokeWidth={2} dot={false} />
                          </LineChart>
                        </ResponsiveContainer>
                      </div>
                    </div>
                  </CardContent>
                </Card>

                <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
                  {members.map((m) => (
                    <MemberCard key={m.id} m={m} onSelect={(id)=>{ setSelectedMemberId(id); setActiveTab("health"); }} />
                  ))}
                </div>
              </div>

              <div className="space-y-4">
                <Card>
                  <CardHeader className="flex-row items-center justify-between">
                    <div>
                      <CardTitle>Upcoming Appointments</CardTitle>
                      <CardDescription>Next 7 days</CardDescription>
                    </div>
                    <Button variant="outline" size="sm" onClick={() => setActiveTab("appointments")} className="gap-2"><CalendarDays className="h-4 w-4" /> Open Calendar</Button>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-3">
                      {next7.length === 0 && (
                        <div className="text-sm text-muted-foreground">No appointments in next 7 days.</div>
                      )}
                      {next7.map((a) => (
                        <div key={a.id} className="rounded-lg border p-3">
                          <div className="flex items-center justify-between">
                            <div className="font-medium">{a.title}</div>
                            <Badge>{format(new Date(a.date), 'EEE, MMM d')}</Badge>
                          </div>
                          <div className="mt-1 text-sm text-muted-foreground">{a.time} • {members.find(m=>m.id===a.memberId)?.name} • {a.doctor}</div>
                          <div className="mt-2 flex items-center gap-2">
                            <Button variant="outline" size="sm" className="gap-1"><Phone className="h-3 w-3" /> Call</Button>
                            <Button variant="outline" size="sm" className="gap-1"><Share2 className="h-3 w-3" /> Share</Button>
                          </div>
                        </div>
                      ))}
                    </div>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader className="flex-row items-center justify-between">
                    <div>
                      <CardTitle>Alert Center</CardTitle>
                      <CardDescription>Prioritized alerts and notifications</CardDescription>
                    </div>
                  </CardHeader>
                  <CardContent className="space-y-3">
                    {alerts.map((al) => (
                      <div key={al.id} className={cn("rounded-lg border p-3", severityColor[al.severity])}>
                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-2">
                            <AlertTriangle className="h-4 w-4" />
                            <div className="font-medium">{al.title}</div>
                          </div>
                          {!al.acknowledged ? (
                            <Button size="sm" variant="outline" onClick={() => acknowledgeAlert(al.id)} className="gap-2">
                              <CheckCircle2 className="h-4 w-4" /> Acknowledge
                            </Button>
                          ) : (
                            <Badge variant="secondary" className="gap-1"><CheckCircle2 className="h-3 w-3" /> Acknowledged</Badge>
                          )}
                        </div>
                        <div className="mt-1 text-xs">{format(new Date(al.time), 'PPpp')} {al.memberId ? `• ${members.find(m=>m.id===al.memberId)?.name}` : ''}</div>
                      </div>
                    ))}
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader>
                    <CardTitle>Care Coordination</CardTitle>
                    <CardDescription>Quick actions for common tasks</CardDescription>
                  </CardHeader>
                  <CardContent className="grid grid-cols-2 gap-2">
                    <Button variant="outline" className="justify-start gap-2"><CalendarDays className="h-4 w-4" /> New Appointment</Button>
                    <Button variant="outline" className="justify-start gap-2"><Pill className="h-4 w-4" /> Send Med Reminder</Button>
                    <Button variant="outline" className="justify-start gap-2"><Users className="h-4 w-4" /> Assign Task</Button>
                    <Button variant="outline" className="justify-start gap-2"><Phone className="h-4 w-4" /> Start Family Call</Button>
                  </CardContent>
                </Card>
              </div>
            </div>
          </TabsContent>

          <TabsContent value="health" className="space-y-6">
            <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
              <Card className="lg:col-span-2">
                <CardHeader className="flex-row items-center justify-between">
                  <div>
                    <CardTitle className="text-xl">Health Monitoring</CardTitle>
                    <CardDescription>Trends for {selectedMember?.name}</CardDescription>
                  </div>
                  <div className="flex items-center gap-2">
                    <Badge variant="secondary" className="gap-1"><Stethoscope className="h-3 w-3" /> Connected</Badge>
                  </div>
                </CardHeader>
                <CardContent className="grid grid-cols-1 gap-4 md:grid-cols-2">
                  <div className="rounded-xl border p-4">
                    <div className="mb-2 flex items-center justify-between">
                      <div className="text-sm font-medium">Heart Rate</div>
                      <Badge variant="secondary">bpm</Badge>
                    </div>
                    <div className="h-48">
                      <ResponsiveContainer width="100%" height="100%">
                        <LineChart data={healthTrends}>
                          <CartesianGrid strokeDasharray="3 3" stroke="#eee" />
                          <XAxis dataKey="date" tickFormatter={(v)=>format(new Date(v), 'MM/dd')} />
                          <YAxis />
                          <Tooltip formatter={(v)=>`${v}`} labelFormatter={(l)=>format(new Date(l), 'PP')} />
                          <Line type="monotone" dataKey="hr" stroke="#0ea5a8" strokeWidth={2} dot={false} />
                        </LineChart>
                      </ResponsiveContainer>
                    </div>
                  </div>
                  <div className="rounded-xl border p-4">
                    <div className="mb-2 flex items-center justify-between">
                      <div className="text-sm font-medium">Blood Pressure</div>
                      <Badge variant="secondary">mmHg</Badge>
                    </div>
                    <div className="h-48">
                      <ResponsiveContainer width="100%" height="100%">
                        <AreaChart data={healthTrends}>
                          <CartesianGrid strokeDasharray="3 3" stroke="#eee" />
                          <XAxis dataKey="date" tickFormatter={(v)=>format(new Date(v), 'MM/dd')} />
                          <YAxis />
                          <Tooltip formatter={(v)=>`${v}`} labelFormatter={(l)=>format(new Date(l), 'PP')} />
                          <Area type="monotone" dataKey="sys" stroke="#60a5fa" fill="#dbeafe" strokeWidth={2} />
                          <Area type="monotone" dataKey="dia" stroke="#4f46e5" fill="#e0e7ff" strokeWidth={2} />
                        </AreaChart>
                      </ResponsiveContainer>
                    </div>
                  </div>
                  <div className="rounded-xl border p-4">
                    <div className="mb-2 flex items-center justify-between">
                      <div className="text-sm font-medium">Daily Steps</div>
                    </div>
                    <div className="h-48">
                      <ResponsiveContainer width="100%" height="100%">
                        <BarChart data={healthTrends}>
                          <CartesianGrid strokeDasharray="3 3" stroke="#eee" />
                          <XAxis dataKey="date" tickFormatter={(v)=>format(new Date(v), 'MM/dd')} />
                          <YAxis />
                          <Tooltip formatter={(v)=>`${v}`} labelFormatter={(l)=>format(new Date(l), 'PP')} />
                          <Bar dataKey="steps" fill="#34d399" />
                        </BarChart>
                      </ResponsiveContainer>
                    </div>
                  </div>
                  <div className="rounded-xl border p-4">
                    <div className="mb-2 flex items-center justify-between">
                      <div className="text-sm font-medium">Sleep Hours</div>
                    </div>
                    <div className="h-48">
                      <ResponsiveContainer width="100%" height="100%">
                        <LineChart data={healthTrends}>
                          <CartesianGrid strokeDasharray="3 3" stroke="#eee" />
                          <XAxis dataKey="date" tickFormatter={(v)=>format(new Date(v), 'MM/dd')} />
                          <YAxis />
                          <Tooltip formatter={(v)=>`${v}`} labelFormatter={(l)=>format(new Date(l), 'PP')} />
                          <Line type="monotone" dataKey="sleep" stroke="#14b8a6" strokeWidth={2} dot={false} />
                        </LineChart>
                      </ResponsiveContainer>
                    </div>
                  </div>
                </CardContent>
              </Card>

              <div className="space-y-4">
                <Card>
                  <CardHeader>
                    <CardTitle>Medication Compliance</CardTitle>
                    <CardDescription>7-day overview</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="flex items-end gap-2">
                      {selectedMember.mood7d.map((v, idx) => (
                        <div key={idx} className="flex flex-1 flex-col items-center gap-1">
                          <div className="h-24 w-full rounded-md bg-primary/10">
                            <div style={{ height: `${v * 20}%` }} className="h-full w-full rounded-md bg-primary" />
                          </div>
                          <div className="text-[10px] text-muted-foreground">{format(addDays(new Date(), idx - 6), 'EEE')}</div>
                        </div>
                      ))}
                    </div>
                    <div className="mt-4 flex items-center justify-between text-sm">
                      <div className="text-muted-foreground">Avg compliance</div>
                      <div className="font-medium">{selectedMember.medicationCompliance}%</div>
                    </div>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader>
                    <CardTitle>Care Goals</CardTitle>
                    <CardDescription>Personalized plan</CardDescription>
                  </CardHeader>
                  <CardContent className="space-y-3">
                    {selectedMember.goals.map((g) => (
                      <div key={g.id} className="rounded-lg border p-3">
                        <div className="flex items-center justify-between">
                          <div className="font-medium">{g.title}</div>
                          <div className="text-xs text-muted-foreground">Owner: {g.owner}</div>
                        </div>
                        <div className="mt-1 text-xs text-muted-foreground">Target: {g.target}</div>
                        <div className="mt-2 flex items-center gap-2">
                          <Progress value={g.progress} className="h-2" />
                          <div className="text-xs font-medium">{g.progress}%</div>
                        </div>
                      </div>
                    ))}
                    <Button variant="outline" className="w-full mt-2">Add Goal</Button>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader>
                    <CardTitle>Integrations</CardTitle>
                    <CardDescription>Connect health data sources</CardDescription>
                  </CardHeader>
                  <CardContent className="space-y-2">
                    <Button variant="outline" className="w-full justify-start gap-2"><Shield className="h-4 w-4" /> Connect EHR (HL7 FHIR)</Button>
                    <Button variant="outline" className="w-full justify-start gap-2"><HeartPulse className="h-4 w-4" /> Connect Apple Health / Google Fit</Button>
                    <Button variant="outline" className="w-full justify-start gap-2"><Users className="h-4 w-4" /> Link Family Chat</Button>
                  </CardContent>
                </Card>
              </div>
            </div>
          </TabsContent>

          <TabsContent value="appointments" className="grid grid-cols-1 gap-6 lg:grid-cols-3">
            <Card className="lg:col-span-2">
              <CardHeader className="flex-row items-center justify-between">
                <div>
                  <CardTitle className="text-xl">Shared Calendar</CardTitle>
                  <CardDescription>{format(new Date(), 'MMMM yyyy')}</CardDescription>
                </div>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-7 gap-2">
                  {Array.from({ length: 42 }).map((_, idx) => {
                    const start = startOfMonth(new Date());
                    const firstWeekday = start.getDay();
                    const day = addDays(start, idx - firstWeekday);
                    const appts = monthlyAppts.filter((a) => isSameDay(new Date(a.date), day));
                    const inMonth = day.getMonth() === start.getMonth();
                    return (
                      <div key={idx} className={cn("min-h-24 rounded-lg border p-2", inMonth ? "bg-background" : "bg-muted/40 text-muted-foreground") }>
                        <div className="mb-1 flex items-center justify-between text-xs">
                          <div className="font-medium">{format(day, 'd')}</div>
                        </div>
                        <div className="space-y-1">
                          {appts.map((a) => (
                            <div key={a.id} className="truncate rounded-md bg-primary/10 px-2 py-1 text-xs">
                              {a.time} • {members.find(m=>m.id===a.memberId)?.name}
                            </div>
                          ))}
                        </div>
                      </div>
                    );
                  })}
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Manage Appointments</CardTitle>
                <CardDescription>Add and share details</CardDescription>
              </CardHeader>
              <CardContent className="space-y-3">
                <Select value={selectedMember?.id} onValueChange={setSelectedMemberId}>
                  <SelectTrigger>
                    <SelectValue placeholder="Member" />
                  </SelectTrigger>
                  <SelectContent>
                    {members.map((m) => (
                      <SelectItem key={m.id} value={m.id}>{m.name}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                <Input id="title" placeholder="Title" />
                <div className="grid grid-cols-2 gap-2">
                  <Input id="date" type="date" />
                  <Input id="time" type="time" />
                </div>
                <Input id="doctor" placeholder="Doctor / Provider" />
                <Input id="location" placeholder="Location" />
                <Textarea id="notes" placeholder="Notes" />
                <div className="flex items-center gap-2">
                  <Button className="flex-1" onClick={() => {
                    const title = (document.getElementById('title') as HTMLInputElement)?.value || 'Appointment';
                    const dateEl = document.getElementById('date') as HTMLInputElement;
                    const time = (document.getElementById('time') as HTMLInputElement)?.value || '09:00';
                    const doctor = (document.getElementById('doctor') as HTMLInputElement)?.value || '';
                    const location = (document.getElementById('location') as HTMLInputElement)?.value || '';
                    const date = dateEl?.value ? new Date(dateEl.value) : addDays(new Date(), 1);
                    addAppointment({ id: `a${appointments.length+1}`, memberId: selectedMemberId, title, doctor, type: 'Visit', date: date.toISOString(), time, location });
                  }}>Add Appointment</Button>
                  <Button variant="outline" className="gap-2"><Upload className="h-4 w-4" /> Share</Button>
                </div>
                <Separator />
                <div className="space-y-2">
                  {appointments.sort((a,b)=> +new Date(a.date) - +new Date(b.date)).slice(0,6).map((a) => (
                    <div key={a.id} className="flex items-center justify-between rounded-md border p-2 text-sm">
                      <div>
                        <div className="font-medium">{a.title}</div>
                        <div className="text-xs text-muted-foreground">{format(new Date(a.date), 'PP')} • {a.time} • {members.find(m=>m.id===a.memberId)?.name}</div>
                      </div>
                      <Button size="icon" variant="ghost"><Phone className="h-4 w-4" /></Button>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="family" className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>Family Members</CardTitle>
                <CardDescription>Profiles, roles, and permissions</CardDescription>
              </CardHeader>
              <CardContent>
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Name</TableHead>
                      <TableHead>Relation</TableHead>
                      <TableHead>Age</TableHead>
                      <TableHead>Role</TableHead>
                      <TableHead>Compliance</TableHead>
                      <TableHead className="text-right">Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {members.map((m) => (
                      <TableRow key={m.id}>
                        <TableCell className="font-medium">{m.name}</TableCell>
                        <TableCell>{m.relation}</TableCell>
                        <TableCell>{m.age}</TableCell>
                        <TableCell><Badge variant="outline">{m.id === selectedMemberId ? 'Primary' : 'Member'}</Badge></TableCell>
                        <TableCell>
                          <div className="flex items-center gap-2">
                            <Progress value={m.medicationCompliance} className="h-2 w-24" />
                            <span className="text-xs">{m.medicationCompliance}%</span>
                          </div>
                        </TableCell>
                        <TableCell className="text-right">
                          <Button size="sm" variant="outline" onClick={()=>setSelectedMemberId(m.id)} className="mr-2">View</Button>
                          <Button size="sm">Edit</Button>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </CardContent>
            </Card>

            <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
              <Card>
                <CardHeader>
                  <CardTitle>Care Team</CardTitle>
                  <CardDescription>Assignments and roles</CardDescription>
                </CardHeader>
                <CardContent className="space-y-3">
                  <div className="flex items-center justify-between rounded-md border p-3">
                    <div>
                      <div className="font-medium">Jane Harper</div>
                      <div className="text-xs text-muted-foreground">Primary Caregiver</div>
                    </div>
                    <Button variant="outline" size="sm">Manage</Button>
                  </div>
                  <div className="flex items-center justify-between rounded-md border p-3">
                    <div>
                      <div className="font-medium">Alex Harper</div>
                      <div className="text-xs text-muted-foreground">Youth Helper</div>
                    </div>
                    <Button variant="outline" size="sm">Manage</Button>
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle>Emergency Contacts</CardTitle>
                  <CardDescription>Priority and escalation</CardDescription>
                </CardHeader>
                <CardContent className="space-y-3">
                  <div className="flex items-center justify-between rounded-md border p-3">
                    <div>
                      <div className="font-medium">911 / Local EMS</div>
                      <div className="text-xs text-muted-foreground">Immediate emergencies</div>
                    </div>
                    <Button variant="destructive" size="sm" className="gap-1"><Phone className="h-3 w-3" /> Call</Button>
                  </div>
                  <div className="flex items-center justify-between rounded-md border p-3">
                    <div>
                      <div className="font-medium">Family Group</div>
                      <div className="text-xs text-muted-foreground">Broadcast alert</div>
                    </div>
                    <Button variant="outline" size="sm">Notify</Button>
                  </div>
                </CardContent>
              </Card>
            </div>
          </TabsContent>

          <TabsContent value="careplans" className="grid grid-cols-1 gap-6 lg:grid-cols-3">
            <Card className="lg:col-span-2">
              <CardHeader>
                <CardTitle>Personalized Care Plan</CardTitle>
                <CardDescription>Goals, tasks, and progress</CardDescription>
              </CardHeader>
              <CardContent className="space-y-3">
                {selectedMember.goals.map((g) => (
                  <div key={g.id} className="rounded-lg border p-3">
                    <div className="flex items-center justify-between">
                      <div className="font-medium">{g.title}</div>
                      <div className="text-xs text-muted-foreground">Owner: {g.owner}</div>
                    </div>
                    <div className="mt-1 text-xs text-muted-foreground">Target: {g.target}</div>
                    <div className="mt-2 flex items-center gap-2">
                      <Progress value={g.progress} className="h-2" />
                      <div className="text-xs font-medium">{g.progress}%</div>
                    </div>
                  </div>
                ))}
                <Button variant="outline">Create Care Plan</Button>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Provider Collaboration</CardTitle>
                <CardDescription>Share plan and updates</CardDescription>
              </CardHeader>
              <CardContent className="space-y-2">
                <Button variant="outline" className="w-full justify-start gap-2"><Share2 className="h-4 w-4" /> Share with Provider</Button>
                <Button variant="outline" className="w-full justify-start gap-2"><Upload className="h-4 w-4" /> Upload Records</Button>
                <Button variant="outline" className="w-full justify-start gap-2"><LinkIcon className="h-4 w-4" /> Connect Portal</Button>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="reports" className="grid grid-cols-1 gap-6 lg:grid-cols-3">
            <Card className="lg:col-span-2">
              <CardHeader className="flex-row items-center justify-between">
                <div>
                  <CardTitle className="text-xl">Professional Reports</CardTitle>
                  <CardDescription>Generate summaries for healthcare providers</CardDescription>
                </div>
                <div className="flex items-center gap-2">
                  <Button variant="outline" className="gap-2" onClick={() => exportCSV("health-summary", healthTrends.map((v)=>({ date: format(new Date(v.date),'yyyy-MM-dd'), hr: v.hr, sys: v.sys, dia: v.dia, steps: v.steps, sleep: v.sleep })))}><Download className="h-4 w-4" /> Export CSV</Button>
                  <Button className="gap-2" onClick={() => window.print()}><FileText className="h-4 w-4" /> Print</Button>
                </div>
              </CardHeader>
              <CardContent>
                <div className="rounded-xl border p-4 print-block">
                  <div className="mb-2 flex items-center justify-between">
                    <div className="text-lg font-semibold">{selectedMember?.name} • Health Summary</div>
                    <div className="text-xs text-muted-foreground">{format(new Date(), 'PPpp')}</div>
                  </div>
                  <div className="grid grid-cols-2 gap-3 text-sm">
                    <div className="rounded-md border p-3">
                      <div className="text-muted-foreground">Resting HR (30d avg)</div>
                      <div className="text-xl font-semibold">{Math.round(healthTrends.reduce((a,v)=>a+v.hr,0)/Math.max(healthTrends.length,1))} bpm</div>
                    </div>
                    <div className="rounded-md border p-3">
                      <div className="text-muted-foreground">BP Avg (30d)</div>
                      <div className="text-xl font-semibold">{Math.round(healthTrends.reduce((a,v)=>a+v.sys,0)/Math.max(healthTrends.length,1))}/{Math.round(healthTrends.reduce((a,v)=>a+v.dia,0)/Math.max(healthTrends.length,1))}</div>
                    </div>
                    <div className="rounded-md border p-3">
                      <div className="text-muted-foreground">Steps Avg</div>
                      <div className="text-xl font-semibold">{Math.round(healthTrends.reduce((a,v)=>a+v.steps,0)/Math.max(healthTrends.length,1))}</div>
                    </div>
                    <div className="rounded-md border p-3">
                      <div className="text-muted-foreground">Sleep Avg</div>
                      <div className="text-xl font-semibold">{(healthTrends.reduce((a,v)=>a+v.sleep,0)/Math.max(healthTrends.length,1)).toFixed(1)} h</div>
                    </div>
                  </div>
                  <div className="mt-4 h-40">
                    <ResponsiveContainer width="100%" height="100%">
                      <LineChart data={healthTrends}>
                        <CartesianGrid strokeDasharray="3 3" stroke="#eee" />
                        <XAxis dataKey="date" tickFormatter={(v)=>format(new Date(v), 'MM/dd')} />
                        <YAxis />
                        <Tooltip formatter={(v)=>`${v}`} labelFormatter={(l)=>format(new Date(l), 'PP')} />
                        <Line type="monotone" dataKey="hr" stroke="#0ea5a8" strokeWidth={2} dot={false} />
                        <Line type="monotone" dataKey="sys" stroke="#60a5fa" strokeWidth={2} dot={false} />
                        <Line type="monotone" dataKey="dia" stroke="#4f46e5" strokeWidth={2} dot={false} />
                      </LineChart>
                    </ResponsiveContainer>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Report Builder</CardTitle>
                <CardDescription>Select data for export</CardDescription>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex items-center justify-between rounded-md border p-3">
                  <div>
                    <div className="font-medium">Medication Compliance</div>
                    <div className="text-xs text-muted-foreground">30-day summary</div>
                  </div>
                  <Button size="sm" variant="outline" onClick={() => exportCSV("medication-compliance", members.map(m=>({ member: m.name, compliance: m.medicationCompliance })))}>Export</Button>
                </div>
                <div className="flex items-center justify-between rounded-md border p-3">
                  <div>
                    <div className="font-medium">Appointments</div>
                    <div className="text-xs text-muted-foreground">Upcoming</div>
                  </div>
                  <Button size="sm" variant="outline" onClick={() => exportCSV("appointments-upcoming", appointments.map(a=>({ date: format(new Date(a.date),'yyyy-MM-dd'), time: a.time, member: members.find(m=>m.id===a.memberId)?.name || '', title: a.title, doctor: a.doctor })))}>Export</Button>
                </div>
                <div className="flex items-center justify-between rounded-md border p-3">
                  <div>
                    <div className="font-medium">Check-in Activity</div>
                    <div className="text-xs text-muted-foreground">Weekly mood</div>
                  </div>
                  <Button size="sm" variant="outline" onClick={() => exportCSV("checkins", selectedMember.mood7d.map((v, i)=>({ day: format(addDays(new Date(), i-6),'EEE'), mood: v })))}>Export</Button>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="alerts" className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>Alert Configuration</CardTitle>
                <CardDescription>Thresholds and notification rules</CardDescription>
              </CardHeader>
              <CardContent className="grid grid-cols-1 gap-4 md:grid-cols-3">
                <div className="rounded-lg border p-3">
                  <div className="text-sm font-medium">BP High Threshold</div>
                  <div className="mt-2 flex items-center gap-2">
                    <Input defaultValue="140/90" />
                    <Switch defaultChecked />
                  </div>
                </div>
                <div className="rounded-lg border p-3">
                  <div className="text-sm font-medium">Medication Missed</div>
                  <div className="mt-2 flex items-center gap-2">
                    <Select defaultValue="high">
                      <SelectTrigger><SelectValue /></SelectTrigger>
                      <SelectContent>
                        <SelectItem value="critical">Critical</SelectItem>
                        <SelectItem value="high">High</SelectItem>
                        <SelectItem value="medium">Medium</SelectItem>
                      </SelectContent>
                    </Select>
                    <Switch defaultChecked />
                  </div>
                </div>
                <div className="rounded-lg border p-3">
                  <div className="text-sm font-medium">Check-in Missed</div>
                  <div className="mt-2 flex items-center gap-2">
                    <Select defaultValue="medium">
                      <SelectTrigger><SelectValue /></SelectTrigger>
                      <SelectContent>
                        <SelectItem value="high">High</SelectItem>
                        <SelectItem value="medium">Medium</SelectItem>
                        <SelectItem value="low">Low</SelectItem>
                      </SelectContent>
                    </Select>
                    <Switch defaultChecked />
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Active Notifications</CardTitle>
                <CardDescription>Handle and escalate</CardDescription>
              </CardHeader>
              <CardContent className="space-y-3">
                {alerts.map((al) => (
                  <div key={al.id} className="flex items-center justify-between rounded-lg border p-3">
                    <div className="flex items-center gap-2">
                      <Badge className={cn(al.severity === 'critical' ? 'bg-red-600' : al.severity === 'high' ? 'bg-amber-600' : 'bg-slate-600')}>{al.severity}</Badge>
                      <div>
                        <div className="font-medium">{al.title}</div>
                        <div className="text-xs text-muted-foreground">{format(new Date(al.time),'PPpp')} {al.memberId ? `• ${members.find(m=>m.id===al.memberId)?.name}` : ''}</div>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      {!al.acknowledged && <Button size="sm" variant="outline" onClick={() => acknowledgeAlert(al.id)}>Acknowledge</Button>}
                      <Button size="sm" variant="outline" className="gap-1"><Phone className="h-3 w-3" /> Call</Button>
                    </div>
                  </div>
                ))}
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="settings" className="grid grid-cols-1 gap-6 lg:grid-cols-2">
            <Card>
              <CardHeader>
                <CardTitle>Privacy and Security</CardTitle>
                <CardDescription>Access control and data handling</CardDescription>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex items-center justify-between rounded-md border p-3">
                  <div>
                    <div className="font-medium">Two-Factor Authentication</div>
                    <div className="text-xs text-muted-foreground">Recommended for caregivers</div>
                  </div>
                  <Switch />
                </div>
                <div className="flex items-center justify-between rounded-md border p-3">
                  <div>
                    <div className="font-medium">Data Encryption at Rest</div>
                    <div className="text-xs text-muted-foreground">Enabled</div>
                  </div>
                  <LockKeyhole className="h-4 w-4" />
                </div>
                <div className="flex items-center justify-between rounded-md border p-3">
                  <div>
                    <div className="font-medium">Share Data with Providers</div>
                    <div className="text-xs text-muted-foreground">Consent required</div>
                  </div>
                  <Switch />
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Integrations</CardTitle>
                <CardDescription>Connect external systems</CardDescription>
              </CardHeader>
              <CardContent className="space-y-2">
                <Button variant="outline" className="w-full justify-start gap-2"><HeartPulse className="h-4 w-4" /> Connect Wearable</Button>
                <Button variant="outline" className="w-full justify-start gap-2"><CalendarDays className="h-4 w-4" /> Sync Calendar</Button>
                <Button variant="outline" className="w-full justify-start gap-2"><Users className="h-4 w-4" /> Family Chat</Button>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>

        <div className="mt-10 rounded-xl border bg-card p-6 text-sm text-muted-foreground">
          <div className="flex flex-wrap items-center gap-3">
            <Shield className="h-4 w-4 text-emerald-600" />
            <span>Designed with healthcare best practices, privacy-first, and role-based access. This demo uses local storage for offline review and mock data sources.</span>
          </div>
        </div>
      </main>

      <footer className="no-print border-t py-6 text-center text-xs text-muted-foreground">
        FamilyBridge • Caregiver Dashboard • {new Date().getFullYear()}
      </footer>
    </div>
  );
}

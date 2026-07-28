import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import api from '../services/api';
import type { IAttendance } from '../types';
import { 
  BarChart, 
  Bar, 
  XAxis, 
  YAxis, 
  Tooltip, 
  ResponsiveContainer, 
  Cell
} from 'recharts';
import { 
  Filter, 
  BarChart3, 
  Clock, 
  FileSpreadsheet, 
  FileText 
} from 'lucide-react';
import './AttendanceHistory.css';

interface ReportSummary {
  totalWorkingDays: number;
  present: number;
  absent: number;
  lateArrivals: number;
  earlyCheckouts: number;
  leavesTaken: number;
  holidayWorkDays: number;
}

interface MonthlyReportResponse {
  startDate: string;
  endDate: string;
  reports: Array<{
    employee: { name: string };
    totalWorkingDays: number;
    present: number;
    absent: number;
    lateArrivals: number;
    earlyCheckouts: number;
    leavesTaken: number;
    holidayWorkDays: number;
  }>;
}

const AttendanceHistory: React.FC = () => {
  const { user } = useAuth();

  // Active tab: 'logs' | 'reports'
  const [activeTab, setActiveTab] = useState<'logs' | 'reports'>('logs');

  // Logs States
  const [history, setHistory] = useState<IAttendance[]>([]);
  const [loadingLogs, setLoadingLogs] = useState(true);

  // Date filters
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');

  // Mobile bottom-sheet filter drawer state
  const [showFilterDrawer, setShowFilterDrawer] = useState(false);

  const handleResetFilters = () => {
    const now = new Date();
    const currentYear = now.getFullYear();
    const currentMonth = String(now.getMonth() + 1).padStart(2, '0');
    setStartDate(`${currentYear}-${currentMonth}-01`);
    const day = String(now.getDate()).padStart(2, '0');
    setEndDate(`${currentYear}-${currentMonth}-${day}`);
  };

  // Report Summary states
  const [summary, setSummary] = useState<ReportSummary | null>(null);
  const [loadingSummary, setLoadingSummary] = useState(true);
  const [exportLoading, setExportLoading] = useState<string | null>(null);

  // Date setup
  useEffect(() => {
    const now = new Date();
    const currentYear = now.getFullYear();
    const currentMonth = String(now.getMonth() + 1).padStart(2, '0');
    
    setStartDate(`${currentYear}-${currentMonth}-01`);
    
    const day = String(now.getDate()).padStart(2, '0');
    setEndDate(`${currentYear}-${currentMonth}-${day}`);
  }, []);

  const fetchLogs = async () => {
    if (!user || !startDate || !endDate) return;
    setLoadingLogs(true);
    try {
      const res = await api.get<IAttendance[]>(`/attendance/history/${user._id}`, {
        params: { startDate, endDate }
      });
      setHistory(res.data);
    } catch (err) {
      console.error('Error fetching logs:', err);
    } finally {
      setLoadingLogs(false);
    }
  };

  const fetchSummary = async () => {
    if (!user) return;
    setLoadingSummary(true);
    try {
      const res = await api.get<MonthlyReportResponse>('/attendance/monthly-report');
      if (res.data && res.data.reports.length > 0) {
        // Find our report
        const report = res.data.reports[0];
        setSummary({
          totalWorkingDays: report.totalWorkingDays,
          present: report.present,
          absent: report.absent,
          lateArrivals: report.lateArrivals,
          earlyCheckouts: report.earlyCheckouts,
          leavesTaken: report.leavesTaken,
          holidayWorkDays: report.holidayWorkDays,
        });
      }
    } catch (err) {
      console.error('Error fetching summary:', err);
    } finally {
      setLoadingSummary(false);
    }
  };

  useEffect(() => {
    if (user && startDate && endDate) {
      fetchLogs();
    }
  }, [user, startDate, endDate]);

  useEffect(() => {
    if (user) {
      fetchSummary();
    }
  }, [user]);

  // Export report API
  const handleExport = async (format: 'excel' | 'pdf', range: 'weekly' | 'monthly') => {
    const loadId = `${range}-${format}`;
    setExportLoading(loadId);
    try {
      const response = await api.get('/attendance/report/export', {
        params: { format, range },
        responseType: 'blob'
      });

      const contentType = response.headers['content-type'];
      const blob = new Blob([response.data], { type: typeof contentType === 'string' ? contentType : undefined });
      const downloadUrl = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = downloadUrl;
      link.download = `attendance_report_${range}_${new Date().toISOString().split('T')[0]}.${format === 'excel' ? 'xlsx' : 'pdf'}`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
    } catch (err) {
      console.error('Export error:', err);
      alert('Failed to download report. Please try again.');
    } finally {
      setExportLoading(null);
    }
  };

  // Log calculation formatting helpers
  const formatTime = (timeStr?: string) => {
    if (!timeStr) return '—';
    return new Date(timeStr).toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit', hour12: true });
  };

  const calculateHours = (checkIn?: string, checkOut?: string) => {
    if (!checkIn || !checkOut) return '—';
    const duration = new Date(checkOut).getTime() - new Date(checkIn).getTime();
    const hours = duration / (1000 * 60 * 60);
    return `${hours.toFixed(1)} hrs`;
  };

  // Recharts Chart Data
  const getChartData = () => {
    if (!summary) return [];
    return [
      { name: 'Present', value: summary.present, color: 'var(--color-success)' },
      { name: 'Absent', value: summary.absent, color: 'var(--color-danger)' },
      { name: 'Late', value: summary.lateArrivals, color: 'var(--color-warning)' },
      { name: 'Leaves', value: summary.leavesTaken, color: 'var(--color-info)' },
    ];
  };

  return (
    <div className="history-container fade-in">
      <header className="history-header-block">
        <div>
          <h1>History & Analytics</h1>
          <p className="subtitle">View daily work logs, analyze attendance stats, and export timesheets.</p>
        </div>

        <div className="history-tabs glass-card">
          <button 
            type="button" 
            className={`tab-btn ${activeTab === 'logs' ? 'active' : ''}`}
            onClick={() => setActiveTab('logs')}
          >
            <Clock size={16} />
            <span>Attendance Log</span>
          </button>
          <button 
            type="button" 
            className={`tab-btn ${activeTab === 'reports' ? 'active' : ''}`}
            onClick={() => setActiveTab('reports')}
          >
            <BarChart3 size={16} />
            <span>Summary & Exports</span>
          </button>
        </div>
      </header>

      {activeTab === 'logs' ? (
        /* Logs view */
        <div className="logs-view-section">
          {/* Desktop Filter Panel */}
          <div className="filters-card glass-card hide-on-mobile">
            <div className="filter-header">
              <Filter size={18} />
              <h4>Filter Logs By Date Range</h4>
            </div>
            
            <div className="filters-inputs-row">
              <div className="form-group">
                <label className="form-label">Start Date</label>
                <input 
                  type="date" 
                  className="form-input"
                  value={startDate}
                  onChange={(e) => setStartDate(e.target.value)}
                />
              </div>

              <div className="form-group">
                <label className="form-label">End Date</label>
                <input 
                  type="date" 
                  className="form-input"
                  value={endDate}
                  onChange={(e) => setEndDate(e.target.value)}
                />
              </div>

              <button className="btn btn-primary filter-submit-btn" onClick={fetchLogs}>
                Apply Filter
              </button>
            </div>
          </div>

          {/* Mobile Filter Bar & Chips */}
          <div className="mobile-filter-bar show-on-mobile">
            <button 
              type="button" 
              className="btn btn-secondary filter-trigger-btn"
              onClick={() => setShowFilterDrawer(true)}
            >
              <Filter size={16} />
              <span>Filter Logs</span>
              {(startDate || endDate) && <span className="active-filter-badge">2</span>}
            </button>
            
            <div className="active-chips-row">
              <span className="filter-chip">
                {startDate ? new Date(startDate).toLocaleDateString(undefined, { month: 'short', day: 'numeric' }) : '—'}
              </span>
              <span className="chip-separator">to</span>
              <span className="filter-chip">
                {endDate ? new Date(endDate).toLocaleDateString(undefined, { month: 'short', day: 'numeric' }) : '—'}
              </span>
              <button type="button" className="btn-reset-text" onClick={handleResetFilters}>Reset</button>
            </div>
          </div>

          <div className="logs-table-card glass-card">
            {loadingLogs ? (
              <p className="text-muted text-center padding-2rem">Loading logs...</p>
            ) : history.length > 0 ? (
              <div className="history-logs-container">
                {/* Desktop Table View */}
                <div className="table-responsive hide-on-mobile">
                  <table className="history-table">
                    <thead>
                      <tr>
                        <th>Date</th>
                        <th>Check In</th>
                        <th>Check Out</th>
                        <th>Work Hours</th>
                        <th>Status Details</th>
                        <th>Exception Approval</th>
                        <th>Remarks</th>
                      </tr>
                    </thead>
                    <tbody>
                      {history.map((log) => (
                        <tr key={log._id}>
                          <td>
                            <strong>{new Date(log.date).toLocaleDateString(undefined, { weekday: 'short', month: 'short', day: 'numeric' })}</strong>
                          </td>
                          <td>{formatTime(log.checkInTime)}</td>
                          <td>{formatTime(log.checkOutTime)}</td>
                          <td>{calculateHours(log.checkInTime, log.checkOutTime)}</td>
                          <td>
                            <div className="badges-list">
                              {log.isLateArrival && <span className="badge badge-warning">LATE</span>}
                              {log.isEarlyCheckout && <span className="badge badge-warning">EARLY OUT</span>}
                              {log.isHolidayWork && <span className="badge badge-info">HOLIDAY WORK</span>}
                              {!log.isLateArrival && !log.isEarlyCheckout && <span className="badge badge-success">COMPLIANT</span>}
                            </div>
                          </td>
                          <td>
                            <span className={`badge badge-${
                              log.approvalStatus === 'APPROVED' ? 'success' : 
                              log.approvalStatus === 'REJECTED' ? 'danger' : 
                              log.approvalStatus === 'PENDING' ? 'warning' : 'info'
                            }`}>
                              {log.approvalStatus === 'NOT_REQUIRED' ? 'NOT REQUIRED' : log.approvalStatus}
                            </span>
                          </td>
                          <td className="remarks-cell">
                            {log.remarks ? <span className="remark-text">"{log.remarks}"</span> : <span className="text-muted italic">—</span>}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>

                {/* Mobile Card List View */}
                <div className="mobile-cards-list show-on-mobile">
                  {history.map((log) => (
                    <div key={log._id} className="mobile-log-card glass-card">
                      <div className="card-row-header">
                        <strong>{new Date(log.date).toLocaleDateString(undefined, { weekday: 'short', month: 'short', day: 'numeric' })}</strong>
                        <span className={`badge badge-${
                          log.approvalStatus === 'APPROVED' ? 'success' : 
                          log.approvalStatus === 'REJECTED' ? 'danger' : 
                          log.approvalStatus === 'PENDING' ? 'warning' : 'info'
                        }`}>
                          {log.approvalStatus === 'NOT_REQUIRED' ? 'NOT REQUIRED' : log.approvalStatus}
                        </span>
                      </div>
                      
                      <div className="card-row-details">
                        <div className="detail-item">
                          <span className="detail-lbl">Timings</span>
                          <span className="detail-val">
                            In: <strong>{formatTime(log.checkInTime)}</strong> | Out: <strong>{formatTime(log.checkOutTime)}</strong>
                          </span>
                        </div>
                        
                        <div className="detail-item">
                          <span className="detail-lbl">Duration</span>
                          <span className="detail-val font-semibold">{calculateHours(log.checkInTime, log.checkOutTime)}</span>
                        </div>
                        
                        <div className="detail-item">
                          <span className="detail-lbl">Status Details</span>
                          <div className="badges-list margin-top-025rem">
                            {log.isLateArrival && <span className="badge badge-warning">LATE</span>}
                            {log.isEarlyCheckout && <span className="badge badge-warning">EARLY OUT</span>}
                            {log.isHolidayWork && <span className="badge badge-info">HOLIDAY WORK</span>}
                            {!log.isLateArrival && !log.isEarlyCheckout && <span className="badge badge-success">COMPLIANT</span>}
                          </div>
                        </div>
                        
                        {log.remarks && (
                          <div className="detail-item remark-box">
                            <span className="detail-lbl">Remarks</span>
                            <span className="detail-val italic">"{log.remarks}"</span>
                          </div>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            ) : (
              <p className="text-muted text-center padding-2rem">No logs found for the selected timeframe.</p>
            )}
          </div>
        </div>
      ) : (
        /* Summary & Export analytics view */
        <div className="reports-view-section">
          {/* Top Quick Stats Row */}
          {summary && (
            <div className="summary-quick-stats">
              <div className="stat-card glass-card">
                <span className="stat-lbl">Days Logged</span>
                <h3>{summary.present} / {summary.totalWorkingDays}</h3>
                <span className="stat-trend success">Present rate: {((summary.present / Math.max(1, summary.totalWorkingDays)) * 100).toFixed(0)}%</span>
              </div>

              <div className="stat-card glass-card">
                <span className="stat-lbl">Late Arrivals</span>
                <h3 className="warning-color">{summary.lateArrivals}</h3>
                <span className="stat-trend warning">Validation pending or resolved</span>
              </div>

              <div className="stat-card glass-card">
                <span className="stat-lbl">Total Leaves Taken</span>
                <h3 className="info-color">{summary.leavesTaken}</h3>
                <span className="stat-trend info">Days absent with credit</span>
              </div>

              <div className="stat-card glass-card">
                <span className="stat-lbl">Holiday Work Days</span>
                <h3 className="success-color">{summary.holidayWorkDays}</h3>
                <span className="stat-trend success">Compensatory off earned</span>
              </div>
            </div>
          )}

          <div className="reports-analytics-grid">
            {/* Chart Card */}
            <div className="chart-card-holder glass-card">
              <h4>Attendance Distribution (Last 30 Days)</h4>
              
              {loadingSummary ? (
                <p className="text-muted">Loading chart analytics...</p>
              ) : summary ? (
                <div style={{ width: '100%', height: 260 }}>
                  <ResponsiveContainer>
                    <BarChart data={getChartData()} margin={{ top: 20, right: 30, left: 0, bottom: 0 }}>
                      <XAxis dataKey="name" stroke="var(--text-muted)" fontSize={12} tickLine={false} />
                      <YAxis stroke="var(--text-muted)" fontSize={12} tickLine={false} />
                      <Tooltip 
                        contentStyle={{ 
                          backgroundColor: 'var(--bg-surface)', 
                          borderColor: 'var(--border-color)',
                          borderRadius: '8px',
                          color: 'var(--text-primary)',
                          fontFamily: "var(--font-primary)"
                        }} 
                      />
                      <Bar dataKey="value" radius={[4, 4, 0, 0]}>
                        {getChartData().map((entry, index) => (
                          <Cell key={`cell-${index}`} fill={entry.color} />
                        ))}
                      </Bar>
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              ) : (
                <p className="text-muted">No analytics reports generated yet.</p>
              )}
            </div>

            {/* Downloader Card */}
            <div className="exports-card glass-card">
              <h4>Export Document Generators</h4>
              <p className="text-muted margin-bottom-1rem">Select and stream official timesheets in Excel or PDF formats.</p>

              <div className="export-options-grid">
                <div className="export-panel-item">
                  <h5>Weekly Timesheet</h5>
                  <p className="panel-desc">Summary of hours, entries, and leaves for the past 7 days.</p>
                  
                  <div className="export-btns">
                    <button 
                      className="btn btn-secondary"
                      onClick={() => handleExport('excel', 'weekly')}
                      disabled={exportLoading === 'weekly-excel'}
                    >
                      <FileSpreadsheet size={16} />
                      <span>{exportLoading === 'weekly-excel' ? 'Building...' : 'Excel'}</span>
                    </button>
                    <button 
                      className="btn btn-secondary"
                      onClick={() => handleExport('pdf', 'weekly')}
                      disabled={exportLoading === 'weekly-pdf'}
                    >
                      <FileText size={16} />
                      <span>{exportLoading === 'weekly-pdf' ? 'Building...' : 'PDF'}</span>
                    </button>
                  </div>
                </div>

                <div className="export-panel-item">
                  <h5>Monthly Timesheet</h5>
                  <p className="panel-desc">Full details of compliance, work timings, and holiday structures for the past 30 days.</p>
                  
                  <div className="export-btns">
                    <button 
                      className="btn btn-primary"
                      onClick={() => handleExport('excel', 'monthly')}
                      disabled={exportLoading === 'monthly-excel'}
                    >
                      <FileSpreadsheet size={16} />
                      <span>{exportLoading === 'monthly-excel' ? 'Building...' : 'Excel'}</span>
                    </button>
                    <button 
                      className="btn btn-primary"
                      onClick={() => handleExport('pdf', 'monthly')}
                      disabled={exportLoading === 'monthly-pdf'}
                    >
                      <FileText size={16} />
                      <span>{exportLoading === 'monthly-pdf' ? 'Building...' : 'PDF'}</span>
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Mobile bottom-sheet filter drawer */}
      {showFilterDrawer && (
        <div className="bottom-sheet-backdrop" onClick={() => setShowFilterDrawer(false)}>
          <div className="bottom-sheet-container animate-slide-up" onClick={(e) => e.stopPropagation()}>
            <div className="bottom-sheet-drag-handle"></div>
            <div className="bottom-sheet-header">
              <h3>Filter Logs</h3>
              <button type="button" className="bottom-sheet-close" onClick={() => setShowFilterDrawer(false)}>&times;</button>
            </div>
            
            <div className="bottom-sheet-body">
              <div className="form-group">
                <label className="form-label">Start Date</label>
                <input 
                  type="date" 
                  className="form-input"
                  value={startDate}
                  onChange={(e) => setStartDate(e.target.value)}
                />
              </div>

              <div className="form-group">
                <label className="form-label">End Date</label>
                <input 
                  type="date" 
                  className="form-input"
                  value={endDate}
                  onChange={(e) => setEndDate(e.target.value)}
                />
              </div>
            </div>
            
            <div className="bottom-sheet-footer">
              <button 
                type="button" 
                className="btn btn-secondary w-full"
                onClick={() => {
                  handleResetFilters();
                  setShowFilterDrawer(false);
                }}
              >
                Reset
              </button>
              <button 
                type="button" 
                className="btn btn-primary w-full"
                onClick={() => {
                  fetchLogs();
                  setShowFilterDrawer(false);
                }}
              >
                Apply
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default AttendanceHistory;

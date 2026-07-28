import React, { useState, useEffect } from 'react';
import api from '../services/api';
import type { IUser } from '../types';
import { 
  CheckCircle, 
  XCircle, 
  FileSpreadsheet, 
  FileText, 
  Filter, 
  CalendarDays
} from 'lucide-react';
import './AdminReports.css';

interface ReportRow {
  employee: {
    _id: string;
    name: string;
    email: string;
    department: string;
  };
  totalWorkingDays: number;
  present: number;
  absent: number;
  lateArrivals: number;
  earlyCheckouts: number;
  leavesTaken: number;
  holidayWorkDays: number;
}

interface ReportResponse {
  startDate: string;
  endDate: string;
  reports: ReportRow[];
}

const AdminReports: React.FC = () => {
  const [employees, setEmployees] = useState<IUser[]>([]);
  const [selectedEmployee, setSelectedEmployee] = useState('');
  const [reportRange, setReportRange] = useState<'weekly' | 'monthly'>('monthly');
  const [reportData, setReportData] = useState<ReportRow[]>([]);
  const [dateRange, setDateRange] = useState({ start: '', end: '' });
  
  // Loaders & Message
  const [loading, setLoading] = useState(true);
  const [exportLoading, setExportLoading] = useState<string | null>(null);
  const [message, setMessage] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  // Fetch employees list to populate dropdown filter
  const fetchEmployeesList = async () => {
    try {
      const res = await api.get<IUser[]>('/employees?status=APPROVED');
      setEmployees(res.data);
    } catch (err) {
      console.error('Error fetching employees list:', err);
    }
  };

  // Fetch report data
  const fetchReport = async () => {
    setLoading(true);
    setMessage(null);
    try {
      const endpoint = reportRange === 'weekly' ? '/attendance/weekly-report' : '/attendance/monthly-report';
      const params: Record<string, string> = {};
      if (selectedEmployee) params.employeeId = selectedEmployee;

      const res = await api.get<ReportResponse>(endpoint, { params });
      setReportData(res.data.reports);
      setDateRange({
        start: res.data.startDate,
        end: res.data.endDate
      });
    } catch (err: any) {
      console.error('Error fetching report:', err);
      setMessage({ text: 'Failed to retrieve attendance report logs.', type: 'error' });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchEmployeesList();
  }, []);

  useEffect(() => {
    fetchReport();
  }, [reportRange, selectedEmployee]);

  // Handle Export Report (PDF or Excel)
  const handleExport = async (format: 'excel' | 'pdf') => {
    setExportLoading(format);
    setMessage(null);
    try {
      const res = await api.get('/attendance/report/export', {
        params: {
          format,
          range: reportRange,
          employeeId: selectedEmployee || undefined
        },
        responseType: 'blob'
      });

      // Create download link from blob response
      const fileType = format === 'excel' 
        ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' 
        : 'application/pdf';
      const blob = new Blob([res.data], { type: fileType });
      const url = window.URL.createObjectURL(blob);
      
      const fileExtension = format === 'excel' ? 'xlsx' : 'pdf';
      const fileName = `attendance_${reportRange}_report_${dateRange.start}_to_${dateRange.end}.${fileExtension}`;
      
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', fileName);
      document.body.appendChild(link);
      link.click();
      
      // Cleanup
      link.remove();
      window.URL.revokeObjectURL(url);
      
      setMessage({ text: `Report successfully downloaded in ${format.toUpperCase()} format.`, type: 'success' });
    } catch (err: any) {
      console.error('Export report error:', err);
      setMessage({ text: 'Failed to export document. Try again.', type: 'error' });
    } finally {
      setExportLoading(null);
    }
  };

  const formatDate = (dateStr: string) => {
    if (!dateStr) return '';
    return new Date(dateStr).toLocaleDateString(undefined, { 
      year: 'numeric', 
      month: 'short', 
      day: 'numeric' 
    });
  };

  return (
    <div className="admin-reports-container fade-in">
      <header className="reports-header-admin">
        <div>
          <h1>Attendance Report Center</h1>
          <p className="subtitle">Compile statistics across the organization and download official audit documents.</p>
        </div>
      </header>

      {message && (
        <div className={`reports-alert alert-${message.type === 'success' ? 'success' : 'danger'}`}>
          {message.type === 'success' ? <CheckCircle size={20} /> : <XCircle size={20} />}
          <span>{message.text}</span>
        </div>
      )}

      {/* Control panel & Filter bar */}
      <div className="reports-control-bar glass-card">
        {/* Toggle Range */}
        <div className="timeframe-toggles">
          <button 
            className={`time-toggle-btn ${reportRange === 'weekly' ? 'active' : ''}`}
            onClick={() => setReportRange('weekly')}
          >
            Weekly Summary (7 days)
          </button>
          <button 
            className={`time-toggle-btn ${reportRange === 'monthly' ? 'active' : ''}`}
            onClick={() => setReportRange('monthly')}
          >
            Monthly Summary (30 days)
          </button>
        </div>

        {/* Filter Selection */}
        <div className="filters-group-row">
          <div className="report-filter-item">
            <Filter size={14} className="decor-ico" />
            <select 
              className="report-filter-select"
              value={selectedEmployee}
              onChange={(e) => setSelectedEmployee(e.target.value)}
            >
              <option value="">All Employees</option>
              {employees.map(emp => (
                <option key={emp._id} value={emp._id}>{emp.name}</option>
              ))}
            </select>
          </div>

          {/* Export Action Buttons */}
          <div className="export-action-buttons">
            <button 
              className="btn btn-secondary btn-export"
              onClick={() => handleExport('excel')}
              disabled={exportLoading !== null || loading}
            >
              <FileSpreadsheet size={16} />
              <span>{exportLoading === 'excel' ? 'Exporting...' : 'Export Excel'}</span>
            </button>
            <button 
              className="btn btn-secondary btn-export"
              onClick={() => handleExport('pdf')}
              disabled={exportLoading !== null || loading}
            >
              <FileText size={16} />
              <span>{exportLoading === 'pdf' ? 'Exporting...' : 'Export PDF'}</span>
            </button>
          </div>
        </div>
      </div>

      {/* Report Summary Data Table */}
      <div className="reports-data-section glass-card">
        <div className="report-period-indicator">
          <CalendarDays size={18} />
          <span>Active Period: <strong>{formatDate(dateRange.start)}</strong> to <strong>{formatDate(dateRange.end)}</strong></span>
        </div>

        {loading ? (
          <div className="table-loading-reports">
            <div className="custom-spinner" />
            <p>COMPILING LOG STATS...</p>
          </div>
        ) : reportData.length > 0 ? (
          <div className="table-responsive">
            <table className="reports-data-table">
              <thead>
                <tr>
                  <th>Employee</th>
                  <th className="hide-on-mobile">Department</th>
                  <th className="center-cell">Working Days</th>
                  <th className="center-cell">Present</th>
                  <th className="center-cell">Absent</th>
                  <th className="center-cell">Late In</th>
                  <th className="center-cell">Early Out</th>
                  <th className="center-cell">Leaves</th>
                  <th className="center-cell">Holiday Work</th>
                </tr>
              </thead>
              <tbody>
                {reportData.map((row) => (
                  <tr key={row.employee._id}>
                    <td>
                      <div className="emp-rep-cell emp-info-cell">
                        <strong>{row.employee.name}</strong>
                        <span className="emp-email">{row.employee.email}</span>
                        <span className="emp-meta-sub show-on-mobile">{row.employee.department || 'No Dept'}</span>
                      </div>
                    </td>
                    <td className="hide-on-mobile">
                      <span className="dept-tag">{row.employee.department || '—'}</span>
                    </td>
                    <td className="center-cell"><strong>{row.totalWorkingDays}</strong></td>

                    <td className="center-cell count-green">{row.present}</td>
                    <td className="center-cell count-red">{row.absent}</td>
                    <td className="center-cell count-yellow">{row.lateArrivals}</td>
                    <td className="center-cell count-yellow">{row.earlyCheckouts}</td>
                    <td className="center-cell count-purple">{row.leavesTaken}</td>
                    <td className="center-cell count-cyan">{row.holidayWorkDays}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <p className="text-muted padding-2rem text-center">No report parameters found.</p>
        )}
      </div>
    </div>
  );
};

export default AdminReports;

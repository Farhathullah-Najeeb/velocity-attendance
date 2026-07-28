import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import api from '../services/api';
import type { IAttendance, ILeaveBalance, IHoliday } from '../types';
import {
  Clock,
  MapPin,
  Calendar,
  AlertTriangle,
  UserCheck,
  CheckCircle,
  XCircle,
  Umbrella,
  Compass,
  RefreshCw
} from 'lucide-react';
import './Dashboard.css';

const EmployeeDashboard: React.FC = () => {
  const { user } = useAuth();

  // Clock state
  const [currentTime, setCurrentTime] = useState(new Date());

  // Attendance state
  const [todayAttendance, setTodayAttendance] = useState<IAttendance | null>(null);
  const [loadingAttendance, setLoadingAttendance] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  const [coords, setCoords] = useState<{ latitude: number; longitude: number } | null>(null);
  const [gpsError, setGpsError] = useState<string | null>(null);

  // Stats and Holidays
  const [leaveBalance, setLeaveBalance] = useState<ILeaveBalance | null>(null);
  const [holidays, setHolidays] = useState<IHoliday[]>([]);
  const [message, setMessage] = useState<{ text: string; type: 'success' | 'error' | 'warning' } | null>(null);

  // Tick clock
  useEffect(() => {
    const timer = setInterval(() => setCurrentTime(new Date()), 1000);
    return () => clearInterval(timer);
  }, []);

  // Fetch today's attendance state
  const fetchTodayAttendance = async () => {
    if (!user) return;
    setLoadingAttendance(true);
    try {
      // Get current date string in IST/local format YYYY-MM-DD
      const year = currentTime.getFullYear();
      const month = String(currentTime.getMonth() + 1).padStart(2, '0');
      const day = String(currentTime.getDate()).padStart(2, '0');
      const dateStr = `${year}-${month}-${day}`;

      const res = await api.get<IAttendance[]>(`/attendance/history/${user._id}`, {
        params: { startDate: dateStr, endDate: dateStr }
      });

      if (res.data && res.data.length > 0) {
        // Today's attendance record found
        setTodayAttendance(res.data[0]);
      } else {
        setTodayAttendance(null);
      }
    } catch (err) {
      console.error('Error fetching today\'s attendance:', err);
    } finally {
      setLoadingAttendance(false);
    }
  };

  // Fetch Leave Balance
  const fetchLeaveBalance = async () => {
    if (!user) return;
    try {
      const res = await api.get<ILeaveBalance>(`/leaves/balance/${user._id}`);
      setLeaveBalance(res.data);
    } catch (err) {
      console.error('Error fetching leave balance:', err);
    }
  };

  // Fetch Holidays
  const fetchHolidays = async () => {
    try {
      const res = await api.get<IHoliday[]>('/holidays');
      setHolidays(res.data.slice(0, 5)); // show top 5 upcoming holidays
    } catch (err) {
      console.error('Error fetching holidays:', err);
    }
  };

  // Geolocation trigger
  const requestLocation = () => {
    if (!navigator.geolocation) {
      setGpsError('Geolocation is not supported by your browser.');
      return;
    }

    setGpsError(null);
    navigator.geolocation.getCurrentPosition(
      (position) => {
        setCoords({
          latitude: position.coords.latitude,
          longitude: position.coords.longitude
        });
      },
      (error) => {
        console.warn('Geolocation access issue:', error.message);
        setGpsError('Could not retrieve precise GPS. Check-in will proceed without coordinates.');
      },
      { enableHighAccuracy: true, timeout: 8000 }
    );
  };

  const handleRefresh = async () => {
    setMessage(null);
    setLoadingAttendance(true);
    try {
      await Promise.all([
        fetchTodayAttendance(),
        fetchLeaveBalance(),
        fetchHolidays()
      ]);
      requestLocation();
    } catch (err) {
      console.error('Error refreshing employee dashboard:', err);
    } finally {
      setLoadingAttendance(false);
    }
  };

  useEffect(() => {
    if (user) {
      fetchTodayAttendance();
      fetchLeaveBalance();
      fetchHolidays();
      requestLocation();
    }
  }, [user]);

  // Handle Check-In
  const handleCheckIn = async () => {
    setActionLoading(true);
    setMessage(null);
    try {
      const payload = coords ? { latitude: coords.latitude, longitude: coords.longitude } : {};
      const res = await api.post('/attendance/check-in', payload);

      setTodayAttendance(res.data.attendance);
      setMessage({
        text: res.data.message || 'Checked in successfully!',
        type: res.data.attendance.isLateArrival ? 'warning' : 'success'
      });
      fetchLeaveBalance(); // Refresh in case compensatory was credited
    } catch (err: any) {
      console.error('Check-in error:', err);
      setMessage({
        text: err.response?.data?.message || 'Check-in failed. Please try again.',
        type: 'error'
      });
    } finally {
      setActionLoading(false);
    }
  };

  // Handle Check-Out
  const handleCheckOut = async () => {
    setActionLoading(true);
    setMessage(null);
    try {
      const payload = coords ? { latitude: coords.latitude, longitude: coords.longitude } : {};
      const res = await api.post('/attendance/check-out', payload);

      setTodayAttendance(res.data.attendance);
      setMessage({
        text: res.data.message || 'Checked out successfully!',
        type: res.data.attendance.isEarlyCheckout ? 'warning' : 'success'
      });
    } catch (err: any) {
      console.error('Check-out error:', err);
      setMessage({
        text: err.response?.data?.message || 'Check-out failed. Please try again.',
        type: 'error'
      });
    } finally {
      setActionLoading(false);
    }
  };

  // Determine Attendance State Text
  const getAttendanceState = () => {
    if (loadingAttendance) return 'LOADING...';
    if (!todayAttendance) return 'NOT CHECKED IN';
    if (todayAttendance.checkOutTime) return 'CHECKED OUT';
    return 'ACTIVE WORK SESSION';
  };

  const getAttendanceStateClass = () => {
    if (!todayAttendance) return 'state-not-in';
    if (todayAttendance.checkOutTime) return 'state-checked-out';
    return 'state-checked-in';
  };

  return (
    <div className="dashboard-container fade-in">
      <header className="dashboard-header">
        <div className="dashboard-title-area">
          <div className="dashboard-title-info">
            <h1>Welcome back, {user?.name}!</h1>
            <p className="subtitle">Track your attendance and manage leaves from your personal hub.</p>
          </div>
          <button 
            type="button" 
            className="btn-circle-refresh" 
            onClick={handleRefresh}
            title="Refresh Data"
            disabled={loadingAttendance}
          >
            <RefreshCw size={18} className={loadingAttendance ? 'spin-animation' : ''} />
          </button>
        </div>
        <div className="current-date-box glass-card">
          <Calendar className="date-icon" size={18} />
          <span>{currentTime.toLocaleDateString(undefined, { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}</span>
        </div>
      </header>

      {message && (
        <div className={`dashboard-alert dashboard-alert-${message.type}`}>
          {message.type === 'success' && <CheckCircle size={20} />}
          {message.type === 'error' && <XCircle size={20} />}
          {message.type === 'warning' && <AlertTriangle size={20} />}
          <div>
            <strong>
              {message.type === 'success' && 'Success: '}
              {message.type === 'error' && 'Error: '}
              {message.type === 'warning' && 'Notice: '}
            </strong>
            {message.text}
          </div>
        </div>
      )}

      <div className="dashboard-grid">
        {/* Attendance Action Panel */}
        <section className="attendance-action-card glass-card">
          <div className={`status-badge-glow ${getAttendanceStateClass()}`}>
            {getAttendanceState()}
          </div>

          <div className="clock-widget">
            <Clock size={40} className="clock-icon-rotating" />
            <h2 className="clock-time">
              {currentTime.toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: true })}
            </h2>
            <p className="clock-label">CURRENT SYSTEM TIME</p>
          </div>

          <div className="gps-coordinate-status">
            <MapPin size={16} />
            {coords ? (
              <span>GPS Connected: {coords.latitude.toFixed(4)}°, {coords.longitude.toFixed(4)}°</span>
            ) : gpsError ? (
              <span className="gps-warning">{gpsError}</span>
            ) : (
              <span>Locating coordinates...</span>
            )}
          </div>

          <div className="action-buttons-group">
            {loadingAttendance ? (
              <div className="loader-element">SYNCING STATUS...</div>
            ) : !todayAttendance ? (
              <button
                type="button"
                className="btn btn-primary checkin-pulse-btn"
                onClick={handleCheckIn}
                disabled={actionLoading}
              >
                {actionLoading ? 'Registering check-in...' : 'CHECK IN NOW'}
              </button>
            ) : !todayAttendance.checkOutTime ? (
              <button
                type="button"
                className="btn btn-danger checkout-pulse-btn"
                onClick={handleCheckOut}
                disabled={actionLoading}
              >
                {actionLoading ? 'Registering check-out...' : 'CHECK OUT NOW'}
              </button>
            ) : (
              <div className="session-completed-label">
                <UserCheck size={20} />
                <span>Work session completed for today. Good job!</span>
              </div>
            )}
          </div>

          {!todayAttendance && !loadingAttendance && (
            <div className="today-log-summary no-log-placeholder">
              <p className="placeholder-text">
                No check-in recorded for today yet. Make sure to tap the button above to register your check-in coordinates and start your active session!
              </p>
            </div>
          )}

          {todayAttendance && (
            <div className="today-log-summary">
              <h4>Today's Log:</h4>
              <div className="log-row">
                <span>Check-in Time:</span>
                <strong>{new Date(todayAttendance.checkInTime).toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit', hour12: true })}</strong>
              </div>
              {todayAttendance.checkOutTime && (
                <div className="log-row">
                  <span>Check-out Time:</span>
                  <strong>{new Date(todayAttendance.checkOutTime).toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit', hour12: true })}</strong>
                </div>
              )}

              <div className="log-row-compliance">
                {todayAttendance.isLateArrival && (
                  <span className="badge badge-warning">LATE ARRIVAL</span>
                )}
                {todayAttendance.isEarlyCheckout && (
                  <span className="badge badge-warning">EARLY CHECKOUT</span>
                )}
                {todayAttendance.isHolidayWork && (
                  <span className="badge badge-info">HOLIDAY WORK</span>
                )}
                {todayAttendance.approvalStatus === 'PENDING' && (
                  <p className="exception-status">Exception validation: <span className="badge badge-warning">PENDING APPROVAL</span></p>
                )}
                {todayAttendance.approvalStatus === 'APPROVED' && (
                  <p className="exception-status">Exception validation: <span className="badge badge-success">APPROVED</span></p>
                )}
              </div>
            </div>
          )}
        </section>

        {/* Leave Balances Panel */}
        <section className="leave-status-card glass-card">
          <div className="card-header-icon">
            <Umbrella size={24} className="accent-color-icon" />
            <h3>Leave Balances</h3>
          </div>

          {leaveBalance ? (
            <div className="leave-progress-grid">
              <div className="leave-progress-item">
                <div className="circular-progress-box">
                  {/* Visual Progress percentage */}
                  <span className="count-large">{leaveBalance.balances.CASUAL.remaining}</span>
                  <span className="count-sub">/ {leaveBalance.balances.CASUAL.allowed} Days</span>
                </div>
                <div className="leave-progress-details">
                  <h4>Casual Leave</h4>
                  <p className="text-muted">Taken: {leaveBalance.balances.CASUAL.taken} days</p>
                </div>
              </div>

              <div className="leave-progress-item">
                <div className="circular-progress-box sick-color">
                  <span className="count-large">{leaveBalance.balances.SICK.remaining}</span>
                  <span className="count-sub">/ {leaveBalance.balances.SICK.allowed} Days</span>
                </div>
                <div className="leave-progress-details">
                  <h4>Sick Leave</h4>
                  <p className="text-muted">Taken: {leaveBalance.balances.SICK.taken} days</p>
                </div>
              </div>

              <div className="leave-progress-item comp-color">
                <div className="circular-progress-box comp-color">
                  <span className="count-large">{leaveBalance.balances.COMPENSATORY.remaining}</span>
                  <span className="count-sub">Credits</span>
                </div>
                <div className="leave-progress-details">
                  <h4>Comp-Off Balance</h4>
                  <p className="text-muted">Earned: {leaveBalance.balances.COMPENSATORY.earned} | Used: {leaveBalance.balances.COMPENSATORY.used}</p>
                </div>
              </div>
            </div>
          ) : (
            <p className="text-muted">Loading leave balance metadata...</p>
          )}
        </section>

        {/* Holidays Panel */}
        <section className="holidays-bulletin glass-card">
          <div className="card-header-icon">
            <Compass size={24} className="accent-color-icon-cyan" />
            <h3>Upcoming Holidays</h3>
          </div>

          <div className="holiday-list-container">
            {holidays.length > 0 ? (
              holidays.map((h) => {
                const holidayDate = new Date(h.date);
                return (
                  <div className="holiday-item" key={h._id}>
                    <div className="holiday-calendar-date">
                      <span className="cal-month">
                        {holidayDate.toLocaleString(undefined, { month: 'short' }).toUpperCase()}
                      </span>
                      <span className="cal-day">
                        {holidayDate.getDate()}
                      </span>
                    </div>
                    <div className="holiday-details">
                      <h5 className="holiday-name">{h.name}</h5>
                      <p className="holiday-day">
                        {holidayDate.toLocaleString(undefined, { weekday: 'long' })}
                      </p>
                    </div>
                  </div>
                );
              })
            ) : (
              <p className="text-muted">No upcoming holidays scheduled.</p>
            )}
          </div>
        </section>
      </div>
    </div>
  );
};

export default EmployeeDashboard;

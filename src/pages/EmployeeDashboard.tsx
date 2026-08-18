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
  const [coords, setCoords] = useState<{ latitude: number; longitude: number; address?: string } | null>(null);
  const [gpsError, setGpsError] = useState<string | null>(null);
  const [isWFH, setIsWFH] = useState(false);

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
      async (position) => {
        const { latitude, longitude } = position.coords;
        let addressStr = '';
        try {
          const geoRes = await fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${latitude}&lon=${longitude}`);
          const geoData = await geoRes.json();
          if (geoData && geoData.display_name) {
            addressStr = geoData.display_name;
          }
        } catch (e) {
          console.warn('Reverse geocoding failed', e);
        }
        
        setCoords({
          latitude,
          longitude,
          address: addressStr
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
      const payload = coords 
        ? { latitude: coords.latitude, longitude: coords.longitude, address: coords.address, isWFH } 
        : { isWFH };
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
      const payload = coords 
        ? { latitude: coords.latitude, longitude: coords.longitude, address: coords.address } 
        : {};
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
            <h1>Welcome back, {user?.name || 'Employee'}!</h1>
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
              <span title={coords.address}>
                GPS Connected: {coords.latitude.toFixed(4)}°, {coords.longitude.toFixed(4)}°
                {coords.address && ` (${coords.address.split(',')[0]})`}
              </span>
            ) : gpsError ? (
              <span className="gps-warning">{gpsError}</span>
            ) : (
              <span>Locating coordinates...</span>
            )}
          </div>
          
          {!todayAttendance && !loadingAttendance && (
            <div className="wfh-toggle-container" style={{ margin: '15px 0', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '10px' }}>
              <label htmlFor="wfh-toggle" style={{ fontWeight: '500', color: 'var(--text-main)' }}>Work From Home</label>
              <div className={`custom-toggle ${isWFH ? 'active' : ''}`} onClick={() => setIsWFH(!isWFH)} style={{ cursor: 'pointer', width: '44px', height: '24px', borderRadius: '12px', background: isWFH ? 'var(--primary-glow)' : 'var(--border-color)', position: 'relative', transition: '0.3s' }}>
                <div style={{ position: 'absolute', top: '2px', left: isWFH ? '22px' : '2px', width: '20px', height: '20px', background: 'white', borderRadius: '50%', transition: '0.3s' }} />
              </div>
            </div>
          )}

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
              {todayAttendance.isWFH && (
                <div className="log-row">
                  <span>Work Mode:</span>
                  <span className="badge badge-info">WORK FROM HOME</span>
                </div>
              )}
              {todayAttendance.checkOutTime && (
                <>
                  <div className="log-row">
                    <span>Check-out Time:</span>
                    <strong>{new Date(todayAttendance.checkOutTime).toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit', hour12: true })}</strong>
                  </div>
                  {todayAttendance.formattedWorkTime && (
                    <div className="log-row">
                      <span>Total Work Duration:</span>
                      <strong>{todayAttendance.formattedWorkTime}</strong>
                    </div>
                  )}
                </>
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

          {leaveBalance?.balances ? (
            <div className="leave-progress-grid">
              <div className="leave-progress-item">
                <div className="circular-progress-box">
                  {/* Visual Progress percentage */}
                  <span className="count-large">{leaveBalance.balances.CASUAL?.remaining || 0}</span>
                  <span className="count-sub">/ {leaveBalance.balances.CASUAL?.allowed || 0} Days</span>
                </div>
                <div className="leave-progress-details">
                  <h4>Casual Leave</h4>
                  <p className="text-muted">Taken: {leaveBalance.balances.CASUAL?.taken || 0} days</p>
                </div>
              </div>

              <div className="leave-progress-item">
                <div className="circular-progress-box sick-color">
                  <span className="count-large">{leaveBalance.balances.SICK?.remaining || 0}</span>
                  <span className="count-sub">/ {leaveBalance.balances.SICK?.allowed || 0} Days</span>
                </div>
                <div className="leave-progress-details">
                  <h4>Sick Leave</h4>
                  <p className="text-muted">Taken: {leaveBalance.balances.SICK?.taken || 0} days</p>
                </div>
              </div>

              <div className="leave-progress-item comp-color">
                <div className="circular-progress-box comp-color">
                  <span className="count-large">{leaveBalance.balances.COMPENSATORY?.remaining || 0}</span>
                  <span className="count-sub">Credits</span>
                </div>
                <div className="leave-progress-details">
                  <h4>Comp-Off Balance</h4>
                  <p className="text-muted">Earned: {leaveBalance.balances.COMPENSATORY?.earned || 0} | Used: {leaveBalance.balances.COMPENSATORY?.used || 0}</p>
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

import React, { useState, useEffect } from 'react';
import api from '../services/api';
import type { ISettings, IHoliday } from '../types';
import { 
  CheckCircle, 
  XCircle, 
  Calendar,
  Clock, 
  Save, 
  CalendarPlus 
} from 'lucide-react';
import './HolidaysSettings.css';

const HolidaysSettings: React.FC = () => {
  // Settings States
  const [officeStartTime, setOfficeStartTime] = useState('09:00');
  const [officeEndTime, setOfficeEndTime] = useState('18:00');
  const [gracePeriod, setGracePeriod] = useState(15);
  const [loadingSettings, setLoadingSettings] = useState(true);
  const [saveLoading, setSaveLoading] = useState(false);

  // Holidays States
  const [holidays, setHolidays] = useState<IHoliday[]>([]);
  const [loadingHolidays, setLoadingHolidays] = useState(true);
  const [holidayDate, setHolidayDate] = useState('');
  const [holidayName, setHolidayName] = useState('');
  const [addHolidayLoading, setAddHolidayLoading] = useState(false);

  // Alerts
  const [message, setMessage] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  const fetchSettings = async () => {
    setLoadingSettings(true);
    try {
      const res = await api.get<ISettings>('/settings');
      if (res.data) {
        setOfficeStartTime(res.data.officeStartTime);
        setOfficeEndTime(res.data.officeEndTime);
        setGracePeriod(res.data.gracePeriod);
      }
    } catch (err) {
      console.error('Error fetching settings:', err);
    } finally {
      setLoadingSettings(false);
    }
  };

  const fetchHolidays = async () => {
    setLoadingHolidays(true);
    try {
      const res = await api.get<IHoliday[]>('/holidays');
      setHolidays(res.data);
    } catch (err) {
      console.error('Error fetching holidays:', err);
    } finally {
      setLoadingHolidays(false);
    }
  };

  useEffect(() => {
    fetchSettings();
    fetchHolidays();
  }, []);

  // Update Settings Handler
  const handleUpdateSettings = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaveLoading(true);
    setMessage(null);
    try {
      await api.patch('/settings', {
        officeStartTime,
        officeEndTime,
        gracePeriod: Number(gracePeriod)
      });
      setMessage({ text: 'Office policy configurations updated successfully.', type: 'success' });
    } catch (err: any) {
      console.error('Update settings error:', err);
      setMessage({ text: err.response?.data?.message || 'Failed to update settings.', type: 'error' });
    } finally {
      setSaveLoading(false);
    }
  };

  // Add Holiday Handler
  const handleAddHoliday = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!holidayDate || !holidayName.trim()) {
      setMessage({ text: 'Please input both a holiday date and a descriptive name.', type: 'error' });
      return;
    }

    setAddHolidayLoading(true);
    setMessage(null);
    try {
      await api.post('/holidays', {
        date: holidayDate,
        name: holidayName.trim()
      });
      setMessage({ text: 'New calendar holiday added successfully.', type: 'success' });
      setHolidayDate('');
      setHolidayName('');
      fetchHolidays();
    } catch (err: any) {
      console.error('Add holiday error:', err);
      setMessage({ text: err.response?.data?.message || 'Failed to register holiday.', type: 'error' });
    } finally {
      setAddHolidayLoading(false);
    }
  };

  const formatDate = (dateStr: string) => {
    return new Date(dateStr).toLocaleDateString(undefined, { 
      year: 'numeric', 
      month: 'long', 
      day: 'numeric' 
    });
  };

  return (
    <div className="holidays-settings-container fade-in">
      <header className="page-header-admin">
        <div>
          <h1>Holidays & Settings</h1>
          <p className="subtitle">Configure corporate office policies, check-in timings, grace intervals and company holidays.</p>
        </div>
      </header>

      {message && (
        <div className={`settings-alert alert-${message.type === 'success' ? 'success' : 'danger'}`}>
          {message.type === 'success' ? <CheckCircle size={20} /> : <XCircle size={20} />}
          <span>{message.text}</span>
        </div>
      )}

      <div className="settings-split-grid">
        {/* Left Card: Office Timings Configurations */}
        <section className="settings-panel-card glass-card">
          <div className="panel-header">
            <Clock size={20} className="panel-header-icon color-blue" />
            <h3>Office Hour Policy Settings</h3>
          </div>

          {loadingSettings ? (
            <div className="panel-loading">
              <div className="custom-spinner" />
              <p>LOADING CONFIGURATIONS...</p>
            </div>
          ) : (
            <form onSubmit={handleUpdateSettings} className="settings-form">
              <div className="form-group">
                <label className="form-label">Office Start Time</label>
                <input 
                  type="time" 
                  className="form-input"
                  value={officeStartTime}
                  onChange={(e) => setOfficeStartTime(e.target.value)}
                  required
                />
                <span className="input-helper-text">Timings after which employees are flagged as Late arrivals.</span>
              </div>

              <div className="form-group">
                <label className="form-label">Office End Time</label>
                <input 
                  type="time" 
                  className="form-input"
                  value={officeEndTime}
                  onChange={(e) => setOfficeEndTime(e.target.value)}
                  required
                />
                <span className="input-helper-text">Timings before which check-outs are flagged as Early checkouts.</span>
              </div>

              <div className="form-group">
                <label className="form-label">Grace Period (Minutes)</label>
                <input 
                  type="number" 
                  className="form-input"
                  min="0"
                  max="120"
                  value={gracePeriod}
                  onChange={(e) => setGracePeriod(Number(e.target.value))}
                  required
                />
                <span className="input-helper-text">Acceptable checking window extension beyond start hours (in minutes).</span>
              </div>

              <button 
                type="submit" 
                className="btn btn-primary save-btn-full"
                disabled={saveLoading}
              >
                <Save size={18} />
                {saveLoading ? 'Saving changes...' : 'Save Settings'}
              </button>
            </form>
          )}
        </section>

        {/* Right Card: Holiday Calendar Management */}
        <section className="settings-panel-card glass-card">
          <div className="panel-header">
            <Calendar size={20} className="panel-header-icon color-cyan" />
            <h3>Holiday Calendar Management</h3>
          </div>

          {/* Form to Add Holiday */}
          <form onSubmit={handleAddHoliday} className="add-holiday-form-inline">
            <div className="form-group">
              <label className="form-label">Holiday Date</label>
              <input 
                type="date" 
                className="form-input"
                value={holidayDate}
                onChange={(e) => setHolidayDate(e.target.value)}
                required
              />
            </div>
            
            <div className="form-group">
              <label className="form-label">Holiday Event Description</label>
              <input 
                type="text" 
                className="form-input"
                placeholder="e.g. Independence Day"
                value={holidayName}
                onChange={(e) => setHolidayName(e.target.value)}
                required
              />
            </div>

            <button 
              type="submit" 
              className="btn btn-primary add-holiday-btn"
              disabled={addHolidayLoading}
            >
              <CalendarPlus size={18} />
              {addHolidayLoading ? 'Adding...' : 'Add Event'}
            </button>
          </form>

          {/* Holiday List Grid */}
          <div className="holiday-list-scroller-section">
            <h4>Registered Holidays</h4>
            {loadingHolidays ? (
              <div className="panel-loading">
                <div className="custom-spinner" />
              </div>
            ) : holidays.length > 0 ? (
              <div className="holidays-grid-view">
                {holidays.map((holiday) => {
                  const dateObj = new Date(holiday.date);
                  return (
                    <div className="holiday-row-item" key={holiday._id}>
                      <div className="holiday-date-badge">
                        <span className="h-month">
                          {dateObj.toLocaleString(undefined, { month: 'short' }).toUpperCase()}
                        </span>
                        <span className="h-day">
                          {dateObj.getDate()}
                        </span>
                      </div>
                      <div className="holiday-desc-text">
                        <h5>{holiday.name}</h5>
                        <p>{formatDate(holiday.date)}</p>
                      </div>
                    </div>
                  );
                })}
              </div>
            ) : (
              <p className="text-muted text-center padding-1rem">No company calendar holidays configured yet.</p>
            )}
          </div>
        </section>
      </div>
    </div>
  );
};

export default HolidaysSettings;

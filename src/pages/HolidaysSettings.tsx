import React, { useState, useEffect } from 'react';
import api from '../services/api';
import { useToast } from '../context/ToastContext';
import SkeletonLoader from '../components/SkeletonLoader';
import EmptyState from '../components/EmptyState';
import ConfirmModal from '../components/ConfirmModal';
import type { ISettings, IHoliday, ILocationPolicy, ISite } from '../types';
import { 
  Clock, 
  Calendar,
  Save,
  CalendarPlus,
  Trash2,
  MapPin,
  Plus,
  Edit2
} from 'lucide-react';
import './HolidaysSettings.css';

const HolidaysSettings: React.FC = () => {
  // Settings States
  const [officeStartTime, setOfficeStartTime] = useState('09:00');
  const [officeEndTime, setOfficeEndTime] = useState('18:00');
  const [gracePeriod, setGracePeriod] = useState(15);
  const [officeLat, setOfficeLat] = useState<number | ''>('');
  const [officeLng, setOfficeLng] = useState<number | ''>('');
  const [allowedRadius, setAllowedRadius] = useState<number>(200);
  const [geofencingEnabled, setGeofencingEnabled] = useState<boolean>(true);
  const [loadingSettings, setLoadingSettings] = useState(true);
  const [saveLoading, setSaveLoading] = useState(false);

  // Holidays States
  const [holidays, setHolidays] = useState<IHoliday[]>([]);
  const [loadingHolidays, setLoadingHolidays] = useState(true);
  const [holidayDate, setHolidayDate] = useState('');
  const [holidayName, setHolidayName] = useState('');
  const [addHolidayLoading, setAddHolidayLoading] = useState(false);

  // Work Sites States
  const [sites, setSites] = useState<ISite[]>([]);
  const [loadingSites, setLoadingSites] = useState(true);
  const [showSiteModal, setShowSiteModal] = useState(false);
  const [editingSite, setEditingSite] = useState<ISite | null>(null);
  const [siteName, setSiteName] = useState('');
  const [siteLat, setSiteLat] = useState<number | ''>('');
  const [siteLng, setSiteLng] = useState<number | ''>('');
  const [siteRadius, setSiteRadius] = useState<number>(500);
  const [siteAddress, setSiteAddress] = useState('');
  const [siteSaving, setSiteSaving] = useState(false);

  // General
  const { showToast } = useToast();
  const setMessage = (msg: { text: string; type: 'success' | 'error' | 'info' } | null) => {
    if (msg) showToast(msg.text, msg.type);
  };
  const [confirmModal, setConfirmModal] = useState<{ isOpen: boolean; title: string; message: string; onConfirm: () => void; isDestructive: boolean }>({
    isOpen: false, title: '', message: '', onConfirm: () => {}, isDestructive: true
  });

  // Location Policies States
  const [locationPolicies, setLocationPolicies] = useState<ILocationPolicy[]>([]);
  const [loadingPolicies, setLoadingPolicies] = useState(true);
  const [savePoliciesLoading, setSavePoliciesLoading] = useState(false);

  const fetchSettings = async () => {
    setLoadingSettings(true);
    try {
      const res = await api.get<ISettings>('/settings');
      if (res.data) {
        setOfficeStartTime(res.data.officeStartTime);
        setOfficeEndTime(res.data.officeEndTime);
        setGracePeriod(res.data.gracePeriod);
        if (res.data.officeLatitude !== undefined) setOfficeLat(res.data.officeLatitude);
        if (res.data.officeLongitude !== undefined) setOfficeLng(res.data.officeLongitude);
        if (res.data.allowedRadiusMeters) setAllowedRadius(res.data.allowedRadiusMeters);
        if (res.data.geofencingEnabled !== undefined) setGeofencingEnabled(res.data.geofencingEnabled);
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

  const fetchLocationPolicies = async () => {
    setLoadingPolicies(true);
    try {
      const res = await api.get<ILocationPolicy[]>('/settings/location-leave-policies');
      setLocationPolicies(res.data || []);
    } catch (err) {
      console.error('Error fetching location policies:', err);
    } finally {
      setLoadingPolicies(false);
    }
  };

  const fetchSites = async () => {
    setLoadingSites(true);
    try {
      const res = await api.get<ISite[]>('/sites');
      setSites(res.data || []);
    } catch (err) {
      console.error('Error fetching sites:', err);
    } finally {
      setLoadingSites(false);
    }
  };

  useEffect(() => {
    fetchSettings();
    fetchHolidays();
    fetchLocationPolicies();
    fetchSites();
  }, []);

  // Update Settings Handler
  const handleUpdateSettings = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaveLoading(true);
    try {
      await api.patch('/settings', {
        officeStartTime,
        officeEndTime,
        gracePeriod: Number(gracePeriod),
        officeLatitude: officeLat !== '' ? Number(officeLat) : undefined,
        officeLongitude: officeLng !== '' ? Number(officeLng) : undefined,
        allowedRadiusMeters: Number(allowedRadius),
        geofencingEnabled
      });
      setMessage({ text: 'Office policy configurations updated successfully.', type: 'success' });
    } catch (err: any) {
      console.error('Update settings error:', err);
      setMessage({ text: err.response?.data?.message || 'Failed to update settings.', type: 'error' });
    } finally {
      setSaveLoading(false);
    }
  };

  const handleGetLocationForOffice = () => {
    if (!navigator.geolocation) {
      showToast('Geolocation is not supported by your browser.', 'error');
      return;
    }
    navigator.geolocation.getCurrentPosition((pos) => {
      setOfficeLat(pos.coords.latitude);
      setOfficeLng(pos.coords.longitude);
      setMessage({ text: 'Current GPS location set as Main Office coordinates.', type: 'success' });
    }, (err) => {
      console.error('Geolocation error:', err);
      showToast('Could not retrieve location: ' + err.message, 'error');
    });
  };

  // Add Holiday Handler
  const handleAddHoliday = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!holidayDate || !holidayName.trim()) {
      setMessage({ text: 'Please input both a holiday date and a descriptive name.', type: 'error' });
      return;
    }

    setAddHolidayLoading(true);
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

  const [deleteLoading, setDeleteLoading] = useState<string | null>(null);

  const handleDeleteHoliday = (id: string) => {
    setConfirmModal({
      isOpen: true,
      title: 'Delete Holiday',
      message: 'Are you sure you want to delete this company holiday?',
      isDestructive: true,
      onConfirm: async () => {
        setDeleteLoading(id);
        try {
          await api.delete(`/holidays/${id}`);
          setMessage({ text: 'Calendar holiday removed successfully.', type: 'success' });
          fetchHolidays();
        } catch (err: any) {
          console.error('Delete holiday error:', err);
          setMessage({ 
            text: err.response?.data?.message || 'Failed to remove calendar holiday.', 
            type: 'error' 
          });
        } finally {
          setDeleteLoading(null);
        }
      }
    });
  };

  // Location Policies Handlers
  const handlePolicyChange = (index: number, field: keyof ILocationPolicy, value: any) => {
    const updated = [...locationPolicies];
    updated[index] = { ...updated[index], [field]: value };
    setLocationPolicies(updated);
  };

  const addPolicy = () => {
    setLocationPolicies([...locationPolicies, { location: '', monthlyPaidLeaveQuota: 1, annualPaidLeaveQuota: 12 }]);
  };

  const removePolicy = (index: number) => {
    const updated = locationPolicies.filter((_, i) => i !== index);
    setLocationPolicies(updated);
  };

  const handleUpdatePolicies = async (e: React.FormEvent) => {
    e.preventDefault();
    setSavePoliciesLoading(true);
    try {
      for (const pol of locationPolicies) {
        if (pol.location.trim()) {
          await api.put('/settings/location-leave-policies', {
            location: pol.location.trim().toUpperCase(),
            monthlyPaidLeaveQuota: Number(pol.monthlyPaidLeaveQuota)
          });
        }
      }
      setMessage({ text: 'Location leave policies saved successfully.', type: 'success' });
      fetchLocationPolicies();
    } catch (err: any) {
      console.error('Save location policies error:', err);
      setMessage({ text: err.response?.data?.message || 'Failed to save location policies.', type: 'error' });
    } finally {
      setSavePoliciesLoading(false);
    }
  };

  // Work Sites Handlers
  const openCreateSiteModal = () => {
    setEditingSite(null);
    setSiteName('');
    setSiteLat('');
    setSiteLng('');
    setSiteRadius(500);
    setSiteAddress('');
    setShowSiteModal(true);
  };

  const openEditSiteModal = (site: ISite) => {
    setEditingSite(site);
    setSiteName(site.name);
    setSiteLat(site.latitude);
    setSiteLng(site.longitude);
    setSiteRadius(site.radiusMeters || 500);
    setSiteAddress(site.address || '');
    setShowSiteModal(true);
  };

  const handleSaveSite = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!siteName || siteLat === '' || siteLng === '') {
      setMessage({ text: 'Please fill in site name, latitude, and longitude.', type: 'error' });
      return;
    }

    setSiteSaving(true);
    try {
      const payload = {
        name: siteName.trim(),
        latitude: Number(siteLat),
        longitude: Number(siteLng),
        radiusMeters: Number(siteRadius),
        address: siteAddress.trim()
      };

      if (editingSite) {
        await api.patch(`/sites/${editingSite._id}`, payload);
        setMessage({ text: 'Work site updated successfully.', type: 'success' });
      } else {
        await api.post('/sites', payload);
        setMessage({ text: 'Work site created successfully.', type: 'success' });
      }

      setShowSiteModal(false);
      fetchSites();
    } catch (err: any) {
      console.error('Save site error:', err);
      setMessage({ text: err.response?.data?.message || 'Failed to save work site.', type: 'error' });
    } finally {
      setSiteSaving(false);
    }
  };

  const handleDeleteSite = (siteId: string) => {
    setConfirmModal({
      isOpen: true,
      title: 'Delete Work Site',
      message: 'Are you sure you want to delete this work site location?',
      isDestructive: true,
      onConfirm: async () => {
        try {
          await api.delete(`/sites/${siteId}`);
          setMessage({ text: 'Work site deleted successfully.', type: 'success' });
          fetchSites();
        } catch (err: any) {
          console.error('Delete site error:', err);
          setMessage({ text: err.response?.data?.message || 'Failed to delete site.', type: 'error' });
        }
      }
    });
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
      <header className="settings-header">
        <div>
          <h1>System Configuration Hub</h1>
          <p className="text-muted">Manage global office timing, company holidays, and authorized branch locations.</p>
        </div>
      </header>

      {/* Confirmation Modal */}
      <ConfirmModal
        isOpen={confirmModal.isOpen}
        title={confirmModal.title}
        message={confirmModal.message}
        onConfirm={() => {
          confirmModal.onConfirm();
          setConfirmModal(prev => ({ ...prev, isOpen: false }));
        }}
        onCancel={() => setConfirmModal(prev => ({ ...prev, isOpen: false }))}
        isDestructive={confirmModal.isDestructive}
      />

      {/* Grid Layout for Configuration Panels */}
      <div className="settings-grid-layout">
        {/* Left Card: Office Timings & Policy Settings */}
        <section className="settings-panel-card glass-card">
          <div className="panel-header">
            <Clock size={20} className="panel-header-icon color-blue" />
            <h3>Office Hours & Attendance Policies</h3>
          </div>

          {loadingSettings ? (
            <SkeletonLoader type="card" count={1} />
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
                <span className="input-helper-text">Official shift start time. Check-ins after this will be marked late.</span>
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

              <div className="form-group" style={{ marginTop: '1rem', paddingTop: '1rem', borderTop: '1px dashed var(--border-color)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <label className="form-label"><strong>Main Office Geofencing Radius (Meters)</strong></label>
                  <label style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', cursor: 'pointer', fontSize: '0.85rem' }}>
                    <input 
                      type="checkbox" 
                      checked={geofencingEnabled} 
                      onChange={(e) => setGeofencingEnabled(e.target.checked)} 
                    />
                    Enable Geofence
                  </label>
                </div>
                <input 
                  type="number" 
                  className="form-input"
                  min="10"
                  max="10000"
                  value={allowedRadius}
                  onChange={(e) => setAllowedRadius(Number(e.target.value))}
                  required
                />
                <span className="input-helper-text">Maximum allowed radius distance (in meters) for check-in validation.</span>
              </div>

              <div className="form-group">
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.25rem' }}>
                  <label className="form-label">Office Coordinates (Lat, Lng)</label>
                  <button type="button" className="btn btn-secondary" onClick={handleGetLocationForOffice} style={{ padding: '2px 8px', fontSize: '0.75rem' }}>
                    <MapPin size={12} /> Use My Current GPS
                  </button>
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.5rem' }}>
                  <input 
                    type="number" 
                    step="any"
                    className="form-input"
                    placeholder="Latitude"
                    value={officeLat}
                    onChange={(e) => setOfficeLat(e.target.value ? Number(e.target.value) : '')}
                  />
                  <input 
                    type="number" 
                    step="any"
                    className="form-input"
                    placeholder="Longitude"
                    value={officeLng}
                    onChange={(e) => setOfficeLng(e.target.value ? Number(e.target.value) : '')}
                  />
                </div>
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
              <SkeletonLoader type="table" count={3} />
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
                      <div className="holiday-desc-text flex-grow-1">
                        <h5>{holiday.name}</h5>
                        <p>{formatDate(holiday.date)}</p>
                      </div>
                      <button 
                        type="button" 
                        className="btn-delete-holiday"
                        title="Delete Holiday"
                        onClick={() => handleDeleteHoliday(holiday._id)}
                        disabled={deleteLoading === holiday._id}
                      >
                        <Trash2 size={16} />
                      </button>
                    </div>
                  );
                })}
              </div>
            ) : (
              <EmptyState title="No Holidays Configured" description="No company calendar holidays configured yet." />
            )}
          </div>
        </section>
      </div>

      {/* Work Sites Section */}
      <section className="settings-panel-card glass-card" style={{ marginTop: '1rem' }}>
        <div className="panel-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <MapPin size={20} className="panel-header-icon color-cyan" />
            <h3>Work Site Locations (Geofencing)</h3>
          </div>
          <button className="btn btn-primary" onClick={openCreateSiteModal}>
            <Plus size={16} /> Add Work Site
          </button>
        </div>

        {loadingSites ? (
          <SkeletonLoader type="table" count={2} />
        ) : sites.length > 0 ? (
          <div className="holidays-grid-view" style={{ marginTop: '1rem' }}>
            {sites.map(site => (
              <div key={site._id} className="holiday-row-item">
                <div className="holiday-desc-text flex-grow-1">
                  <h5>{site.name}</h5>
                  <p>Lat: {site.latitude}, Lng: {site.longitude} | Radius: {site.radiusMeters || 500}m</p>
                  {site.address && <p className="text-muted">{site.address}</p>}
                </div>
                <div style={{ display: 'flex', gap: '0.5rem' }}>
                  <button className="btn-delete-holiday" onClick={() => openEditSiteModal(site)}>
                    <Edit2 size={16} />
                  </button>
                  <button className="btn-delete-holiday" onClick={() => handleDeleteSite(site._id)}>
                    <Trash2 size={16} />
                  </button>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <EmptyState title="No Sites Configured" description="No work site locations configured yet." />
        )}
      </section>

      {/* Location Policies Section */}
      <section className="settings-panel-card glass-card" style={{ marginTop: '1rem' }}>
        <div className="panel-header">
          <MapPin size={20} className="panel-header-icon color-cyan" />
          <h3>Location-based Leave Quota Policies</h3>
        </div>
        
        {loadingPolicies ? (
          <SkeletonLoader type="card" count={1} />
        ) : (
          <form onSubmit={handleUpdatePolicies} className="settings-form">
            <p className="subtitle" style={{ margin: 0, fontSize: '0.85rem' }}>
              Define monthly paid leave quotas per location. Leave requests from a specific location will be validated against its active quota limit.
            </p>
            
            <div className="policies-list">
              {locationPolicies.map((policy, index) => (
                <div key={index} className="policy-row" style={{ display: 'flex', gap: '1rem', alignItems: 'center', marginBottom: '1rem' }}>
                  <div className="form-group" style={{ flex: 1, margin: 0 }}>
                    <label className="form-label">Location Name</label>
                    <input 
                      type="text" 
                      className="form-input"
                      placeholder="e.g. KERALA"
                      value={policy.location}
                      onChange={(e) => handlePolicyChange(index, 'location', e.target.value)}
                      required
                    />
                  </div>
                  <div className="form-group" style={{ flex: 1, margin: 0 }}>
                    <label className="form-label">Monthly Paid Leave Quota</label>
                    <input 
                      type="number" 
                      className="form-input"
                      min="0"
                      value={policy.monthlyPaidLeaveQuota}
                      onChange={(e) => handlePolicyChange(index, 'monthlyPaidLeaveQuota', Number(e.target.value))}
                      required
                    />
                  </div>
                  <button 
                    type="button" 
                    className="btn-delete-holiday"
                    style={{ marginTop: '20px' }}
                    onClick={() => removePolicy(index)}
                  >
                    <Trash2 size={16} />
                  </button>
                </div>
              ))}
            </div>

            <button type="button" className="btn btn-secondary" onClick={addPolicy} style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', alignSelf: 'flex-start' }}>
              <Plus size={16} /> Add Location Policy
            </button>

            <button 
              type="submit" 
              className="btn btn-primary save-btn-full"
              disabled={savePoliciesLoading}
            >
              <Save size={18} />
              {savePoliciesLoading ? 'Saving changes...' : 'Save Location Policies'}
            </button>
          </form>
        )}
      </section>

      {/* Work Site Modal */}
      {showSiteModal && (
        <div className="modal-backdrop">
          <div className="modal-box glass-card fade-in">
            <div className="modal-header">
              <h3>{editingSite ? 'Edit Work Site' : 'Create Work Site'}</h3>
              <button className="modal-close-btn" onClick={() => setShowSiteModal(false)}>&times;</button>
            </div>
            <form onSubmit={handleSaveSite}>
              <div className="modal-body">
                <div className="form-group">
                  <label className="form-label">Site Name <span className="required-star">*</span></label>
                  <input type="text" className="form-input" value={siteName} onChange={(e) => setSiteName(e.target.value)} required />
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                  <div className="form-group">
                    <label className="form-label">Latitude <span className="required-star">*</span></label>
                    <input type="number" step="any" className="form-input" value={siteLat} onChange={(e) => setSiteLat(e.target.value ? Number(e.target.value) : '')} required />
                  </div>
                  <div className="form-group">
                    <label className="form-label">Longitude <span className="required-star">*</span></label>
                    <input type="number" step="any" className="form-input" value={siteLng} onChange={(e) => setSiteLng(e.target.value ? Number(e.target.value) : '')} required />
                  </div>
                </div>
                <div className="form-group">
                  <label className="form-label">Allowed Radius (Meters)</label>
                  <input type="number" className="form-input" value={siteRadius} onChange={(e) => setSiteRadius(Number(e.target.value))} min="50" />
                </div>
                <div className="form-group">
                  <label className="form-label">Site Address</label>
                  <textarea className="form-textarea" value={siteAddress} onChange={(e) => setSiteAddress(e.target.value)} />
                </div>
              </div>
              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={() => setShowSiteModal(false)}>Cancel</button>
                <button type="submit" className="btn btn-primary" disabled={siteSaving}>
                  {siteSaving ? 'Saving...' : 'Save Site'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default HolidaysSettings;

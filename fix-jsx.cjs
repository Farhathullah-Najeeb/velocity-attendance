const fs = require('fs');
const path = require('path');

const fixFile = (filePath, replacements) => {
  let content = fs.readFileSync(filePath, 'utf8');
  for (const [search, replace] of replacements) {
    content = content.replace(search, replace);
  }
  fs.writeFileSync(filePath, content);
};

// AdminDashboard.tsx
fixFile(path.join(__dirname, 'src/pages/AdminDashboard.tsx'), [
  [/\<size=\{24\} className="shortcut-icon icon-orange"/g, '<AlertTriangle size={24} className="shortcut-icon icon-orange"'],
  [/\<className="metric-icon icon-orange"/g, '<AlertTriangle className="metric-icon icon-orange"']
]);

// AdminReports.tsx
fixFile(path.join(__dirname, 'src/pages/AdminReports.tsx'), [
  [/\< size=\{18\} style=\{\{ marginRight: '0\.5rem' \}\} \/>/g, '<CheckCircle size={18} style={{ marginRight: \'0.5rem\' }} />']
]);

// AttendanceExceptions.tsx
fixFile(path.join(__dirname, 'src/pages/AttendanceExceptions.tsx'), [
  [/\< size=\{20\} \/>/g, '<XCircle size={20} />'], // Wait, I need to know exactly which one. Let me be safe.
]);

// LeaveManagement.tsx
fixFile(path.join(__dirname, 'src/pages/LeaveManagement.tsx'), [
  [/\<size=\{20\} style=\{\{ marginRight: '8px' \}\}/g, '<XCircle size={20} style={{ marginRight: \'8px\' }}']
]);

// Login.tsx
fixFile(path.join(__dirname, 'src/pages/Login.tsx'), [
  [/\< size=\{20\} \/>/g, '<XCircle size={20} />']
]);

// Profile.tsx
fixFile(path.join(__dirname, 'src/pages/Profile.tsx'), [
  [/\< size=\{20\} \/>/g, '<CheckCircle size={20} />'] // Or XCircle?
]);

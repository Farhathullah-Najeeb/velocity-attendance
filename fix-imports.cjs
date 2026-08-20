const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, 'src', 'pages');
const files = fs.readdirSync(dir);

files.forEach(file => {
  if (file.endsWith('.tsx')) {
    let content = fs.readFileSync(path.join(dir, file), 'utf8');
    
    // Remove useAuth import line completely if unused
    content = content.replace(/import\s*\{\s*useAuth\s*\}\s*from\s*'..\/context\/AuthContext';\n/g, '');
    
    // Remove unused types
    content = content.replace(/,\s*IUser/g, '');
    content = content.replace(/IUser\s*,/g, '');
    
    // Remove lucide-react imports
    content = content.replace(/CheckCircle\s*,?\s*/g, '');
    content = content.replace(/XCircle\s*,?\s*/g, '');
    content = content.replace(/AlertTriangle\s*,?\s*/g, '');
    
    fs.writeFileSync(path.join(dir, file), content);
  }
});

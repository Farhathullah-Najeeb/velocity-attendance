export interface IRole {
  _id: string;
  name: string;
  permissions: string[];
  description?: string;
  createdAt?: string;
  updatedAt?: string;
}

export interface IUser {
  _id: string;
  name: string;
  email: string;
  role: 'EMPLOYEE' | 'ADMIN' | 'SUPER_ADMIN';
  department?: string;
  isActive?: boolean;
  isApproved?: boolean;
  customRole?: IRole;
  permissions?: string[];
  createdAt?: string;
  updatedAt?: string;
}

export interface IGpsCoords {
  latitude: number;
  longitude: number;
}

export interface IAttendance {
  _id: string;
  employeeId: string | IUser;
  date: string;
  dateStr: string;
  checkInTime: string;
  checkOutTime?: string;
  checkInGps?: IGpsCoords;
  checkOutGps?: IGpsCoords;
  isLateArrival: boolean;
  isEarlyCheckout: boolean;
  isHolidayWork: boolean;
  approvalStatus: 'PENDING' | 'APPROVED' | 'REJECTED' | 'NOT_REQUIRED';
  remarks?: string;
  approvedBy?: string;
  createdAt?: string;
  updatedAt?: string;
}

export type LeaveType = 'CASUAL' | 'SICK' | 'COMPENSATORY' | 'OTHER';

export interface ILeave {
  _id: string;
  employeeId: string | IUser;
  type: LeaveType;
  fromDate: string;
  toDate: string;
  reason: string;
  status: 'PENDING' | 'APPROVED' | 'REJECTED';
  remarks?: string;
  approvedBy?: string;
  createdAt?: string;
  updatedAt?: string;
}

export interface ILeaveBalanceDetail {
  allowed?: number;
  taken: number;
  remaining: number;
  earned?: number;
  used?: number;
}

export interface ILeaveBalance {
  employee: {
    _id: string;
    name: string;
    email: string;
    department: string;
  };
  balances: {
    CASUAL: ILeaveBalanceDetail;
    SICK: ILeaveBalanceDetail;
    COMPENSATORY: ILeaveBalanceDetail;
    OTHER: {
      taken: number;
    };
  };
}

export interface IHoliday {
  _id: string;
  date: string;
  name: string;
  dateStr?: string;
}

export interface ISettings {
  officeStartTime: string;
  officeEndTime: string;
  gracePeriod: number;
}

export interface ILoginResponse {
  _id: string;
  name: string;
  email: string;
  role: 'EMPLOYEE' | 'ADMIN' | 'SUPER_ADMIN';
  access_token: string;
  token_type: string;
}

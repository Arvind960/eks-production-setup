# METHOD OF PROCEDURE (MOP)
## EKS Node Group Update with Launch Template Changes

**Document Version**: 1.0  
**Date**: December 30, 2025  
**Cluster**: eks-terraform-cluster  
**Environment**: Production  

---

## 📋 **PROCEDURE OVERVIEW**

**Purpose**: Update EKS node group to use new launch template version  
**Duration**: 15-20 minutes  
**Downtime**: Zero (rolling update)  
**Risk Level**: Medium  

---

## 🎯 **PRE-EXECUTION CHECKLIST**

### **Prerequisites**
- [ ] AWS Console access with EKS/EC2 permissions
- [ ] Maintenance window scheduled (if required)
- [ ] Application health monitoring enabled
- [ ] Backup of current configuration documented
- [ ] Rollback plan prepared

### **Information Required**
- [ ] **Cluster Name**: `eks-terraform-cluster`
- [ ] **Node Group Name**: `workers-launch-template-fixed`
- [ ] **Launch Template**: `eks-workers-launch-template`
- [ ] **Current Version**: `4`
- [ ] **Target Changes**: _[Document specific changes needed]_

### **Validation**
- [ ] Current node group status: **ACTIVE**
- [ ] All nodes status: **Ready**
- [ ] No ongoing cluster operations
- [ ] Application pods: **Running**

---

## 🔧 **EXECUTION STEPS**

### **PHASE 1: CREATE NEW LAUNCH TEMPLATE VERSION**

#### **Step 1.1: Access Launch Templates**
- [ ] Open AWS Console → Services → EC2
- [ ] Navigate: Left Panel → Instances → Launch Templates
- [ ] Locate: `eks-workers-launch-template`
- [ ] Click on template name

#### **Step 1.2: Create New Version**
- [ ] Click: **Actions** → **Create template version**
- [ ] Source version: Select current version (`4`)
- [ ] Version description: `Production update v5 - [DATE]`

#### **Step 1.3: Apply Configuration Changes**
**[Check applicable changes]**

**AMI Update:**
- [ ] Application and OS Images → Browse more AMIs
- [ ] Search: `amazon-eks-node-1.33`
- [ ] Select: New EKS optimized AMI
- [ ] Record new AMI ID: `_________________`

**Instance Type Change:**
- [ ] Instance type dropdown
- [ ] Change from: `t3.small` to: `_________________`

**Storage Modification:**
- [ ] Storage section → Edit volume
- [ ] Size: Change to `_____` GB
- [ ] Encryption: Enable if not already
- [ ] Volume type: `gp3`

**User Data Update:**
- [ ] Advanced details → User data
- [ ] Verify bootstrap script:
```bash
#!/bin/bash
/etc/eks/bootstrap.sh eks-terraform-cluster
```

#### **Step 1.4: Create Version**
- [ ] Click: **Create template version**
- [ ] **Record new version number**: `_____`
- [ ] Verify creation successful

---

### **PHASE 2: UPDATE NODE GROUP**

#### **Step 2.1: Access EKS Console**
- [ ] AWS Console → Services → EKS
- [ ] Clusters → `eks-terraform-cluster`
- [ ] Compute → Node groups
- [ ] Click: `workers-launch-template-fixed`

#### **Step 2.2: Initiate Update**
- [ ] Click: **Update** button
- [ ] Select: **Launch template**
- [ ] Launch template: Keep `eks-workers-launch-template`
- [ ] Version: Change from `4` to `_____` (new version)

#### **Step 2.3: Configure Update Strategy**
- [ ] Update strategy: **Rolling update**
- [ ] Max unavailable: `1`
- [ ] Max unavailable percentage: Leave blank
- [ ] Click: **Next**

#### **Step 2.4: Execute Update**
- [ ] Review all settings
- [ ] Click: **Update**
- [ ] **Start Time**: `_____:_____`
- [ ] Confirm update initiated

---

### **PHASE 3: MONITOR UPDATE PROGRESS**

#### **Step 3.1: Monitor Node Group Status**
- [ ] EKS Console → Node group details
- [ ] Status: Should show `UPDATING`
- [ ] Resources tab: Monitor instance changes
- [ ] Refresh every 30 seconds

**Progress Tracking:**
- [ ] **5 min**: New instances launching
- [ ] **10 min**: Old instances draining
- [ ] **15 min**: Update completing
- [ ] **Status**: `ACTIVE`

#### **Step 3.2: Monitor EC2 Instances**
- [ ] EC2 Console → Instances
- [ ] Filter: `eks-terraform-cluster`
- [ ] Watch instance lifecycle:
  - [ ] New instances: `Pending` → `Running`
  - [ ] Old instances: `Running` → `Shutting-down`

#### **Step 3.3: Verify Instance Configuration**
- [ ] Click new instance
- [ ] Details → Launch template: `eks-workers-launch-template (v____)`
- [ ] Verify AMI: `_________________`
- [ ] Verify instance type: `_________________`
- [ ] Launch time: Recent

---

### **PHASE 4: POST-UPDATE VALIDATION**

#### **Step 4.1: Node Status Verification**
- [ ] EKS Console → Resources → Nodes
- [ ] All nodes status: **Ready**
- [ ] Node count matches desired size: `_____`
- [ ] No nodes in **NotReady** state

#### **Step 4.2: Application Health Check**
- [ ] EKS Console → Resources → Workloads
- [ ] All pods status: **Running**
- [ ] No pods in **Pending** or **Failed** state
- [ ] Application endpoints responding

#### **Step 4.3: Cluster Component Status**
- [ ] Cluster autoscaler: **Running**
- [ ] Metrics server: **Running**
- [ ] HPA: **Active** with metrics

---

## ✅ **SUCCESS CRITERIA**

### **Update Successful When:**
- [ ] Node group status: **ACTIVE**
- [ ] All instances: **Running** with new launch template
- [ ] All Kubernetes nodes: **Ready**
- [ ] Applications: **Healthy** and responsive
- [ ] No error events in node group
- [ ] **Completion Time**: `_____:_____`

---

## 🚨 **ROLLBACK PROCEDURE**

### **If Update Fails:**

#### **Step R.1: Immediate Rollback**
- [ ] EKS Console → Node group → **Update**
- [ ] Launch template → Version: Revert to `4`
- [ ] Update strategy: **Rolling update**
- [ ] Execute rollback

#### **Step R.2: Monitor Rollback**
- [ ] Watch status return to **ACTIVE**
- [ ] Verify old configuration restored
- [ ] Check application health

#### **Step R.3: Incident Documentation**
- [ ] Document failure reason
- [ ] Capture error logs
- [ ] Update procedure if needed

---

## 📊 **EXECUTION LOG**

### **Timeline**
| Time | Phase | Status | Notes |
|------|-------|--------|-------|
| ___:___ | Pre-check | ⏳ | |
| ___:___ | Template v5 | ⏳ | |
| ___:___ | Update start | ⏳ | |
| ___:___ | Monitoring | ⏳ | |
| ___:___ | Validation | ⏳ | |
| ___:___ | Complete | ⏳ | |

### **Configuration Changes Applied**
- [ ] **AMI**: `ami-xxxxxxxx` → `ami-xxxxxxxx`
- [ ] **Instance Type**: `t3.small` → `___________`
- [ ] **Storage**: `20GB` → `____GB`
- [ ] **Other**: `_________________________`

### **Issues Encountered**
- [ ] None
- [ ] Issue 1: `_________________________`
- [ ] Issue 2: `_________________________`

---

## 👥 **EXECUTION TEAM**

### **Roles and Responsibilities**
- **Primary Executor**: `_________________`
- **Secondary/Observer**: `_________________`
- **Application Owner**: `_________________`
- **Escalation Contact**: `_________________`

### **Sign-off**
- [ ] **Executed by**: `_________________` Date: `_______`
- [ ] **Verified by**: `_________________` Date: `_______`
- [ ] **Approved by**: `_________________` Date: `_______`

---

## 📞 **EMERGENCY CONTACTS**

### **Escalation Path**
1. **Level 1**: Infrastructure Team - `___________`
2. **Level 2**: AWS Support - `___________`
3. **Level 3**: Management - `___________`

### **Communication**
- **Slack Channel**: `#infrastructure`
- **Email List**: `ops-team@company.com`
- **Status Page**: `status.company.com`

---

## 📚 **REFERENCE DOCUMENTS**

- **Launch Template Guide**: `LAUNCH-TEMPLATE-GUI-STEPS.md`
- **EKS AMI Guide**: `EKS-AMI-GUI-SEARCH-GUIDE.md`
- **Troubleshooting**: `AMI-CHANGE-STEPS.md`
- **Architecture**: `README.md`

---

**END OF PROCEDURE**

*This MOP ensures consistent, safe execution of EKS node group updates with proper validation and rollback procedures.*

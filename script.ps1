# Setting AWS Credentials
# This set of accesskey and secretkey are from my own account's admin user
Set-AWSCredential -AccessKey AKIAISFQ46LHYZE4CCMA -SecretKey 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 -StoreAs MichaelAdmin
Initialize-AWSDefaultConfiguration -ProfileName MichaelAdmin -Region ap-southeast-2


# Create a new VPC with CIDR 10.255.0.0/16
$vpcNew = New-EC2VPC -CidrBlock '10.255.0.0/16'
$vpcNewId = $vpcNew.VpcId

# Create a new internet gateway
$igwNew = New-EC2InternetGateway
$igwNewId = $igwNew.InternetGatewayId

# Attach internet gateway to vpc created above
Add-EC2InternetGateway -InternetGatewayId $igwNewId -VpcId $vpcNewId

# Create new Route Table
$routeTableNew = New-EC2RouteTable -VpcId $vpcNewId
$routeTableNewId = $routeTableNew.RouteTableId

# Create new Route to access internet
$routeToInternet = New-EC2Route -RouteTableId $routeTableNewId -GatewayId $igwNewId -DestinationCidrBlock '0.0.0.0/0'

# Create a new Subnet and associate with route table created above
$subnet1 = New-EC2Subnet -VpcId $vpcNewId -CidrBlock '10.255.1.0/24' -AvailabilityZone 'ap-southeast-2a'
$subnet1Id = $subnet1.SubnetId
Register-EC2RouteTable -RouteTableId $routeTableNewId -SubnetId $subnet1Id

# Create a new Security Group
$securityGroupNew = New-EC2SecurityGroup -GroupName TruliooGroup -Description 'For EC2 instances used in Trulioo interview' -VpcId $vpcNewId
# Search and get the actual security group to make it possible to get the Security Group ID to be used later
$sg = Get-EC2SecurityGroup -Region ap-southeast-2 | ?{$_.Description -eq 'For EC2 instances used in Trulioo interview'}
$sgID = $sg.GroupId
Write-Output "SG ID: $sgID"

# Add inbound rules
# Note: GroupId MUST be used instead of GroupName because it is not default VPC
Grant-EC2SecurityGroupIngress -GroupId $SgID -IpPermission @{IpProtocol = 'tcp'; FromPort = 3389; ToPort = 3389; IpRanges = @("172.16.1.1/32")}
Grant-EC2SecurityGroupIngress -GroupId $SgID -IpPermission @{IpProtocol = 'tcp'; FromPort = 80; ToPort = 80; IpRanges = @("0.0.0.0/0")}
Grant-EC2SecurityGroupIngress -GroupId $SgID -IpPermission @{IpProtocol = 'tcp'; FromPort = 443; ToPort = 443; IpRanges = @("0.0.0.0/0")}

# Create a root device mapping for the new instance
$mapping = New-Object -TypeName Amazon.EC2.Model.BlockDeviceMapping
$rootDevice = New-Object -TypeName Amazon.EC2.Model.EbsBlockDevice
$mapping.DeviceName = '/dev/sda1'
$rootDevice.VolumeSize = '30'
$mapping.Ebs = $rootDevice

# Create a second volume mapping for the new instance
$secondMapping = New-Object -TypeName Amazon.EC2.Model.BlockDeviceMapping
$device = New-Object -TypeName Amazon.EC2.Model.EbsBlockDevice
$secondMapping.DeviceName = 'xvdf'
$device.VolumeSize = '10'
$secondMapping.Ebs = $device

# Launch an instance
$instance = New-EC2Instance -ImageId ami-307fa852 -MinCount 1 -MaxCount 1 -KeyName TruliooInterview -SecurityGroupId $sgID -InstanceType t2.micro -SubnetId $subnet1Id -DisableApiTermination $true -BlockDeviceMapping $mapping, $secondMapping

# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: IPv4 netmask conversion
#   input :     $1     : value (nn or nnn.nnn.nnn.nnn)
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# --- private ip address ------------------------------------------------------
# class | ipv4 address range            | subnet mask range
#   a   | 10.0.0.0    - 10.255.255.255  | 255.0.0.0     - 255.255.255.255 (up to 16,777,214 devices can be connected)
#   b   | 172.16.0.0  - 172.31.255.255  | 255.255.0.0   - 255.255.255.255 (up to     65,534 devices can be connected)
#   c   | 192.168.0.0 - 192.168.255.255 | 255.255.255.0 - 255.255.255.255 (up to        254 devices can be connected)
# shellcheck disable=SC2148,SC2317,SC2329
fnIPv4Netmask_mawk() {
	echo "${1:?}" |
		mawk -F '.' '
			# --- and ---------------------------------------------------------
			function fnAnd(x1,x2, res,bit) {
				res=0
				bit=1
				while (x1>0 && x2>0) {
					if (((x1%2)==1) && ((x2%2)==1))
						res+=bit
					x1=int(x1/2)
					x2=int(x2/2)
					bit*=2
				}
				return res
			}
			# --- or ----------------------------------------------------------
			function fnOr(x1,x2, res,bit) {
				res=0
				bit=1
				while (x1>0 || x2>0) {
					if (((x1%2)==1) || ((x2%2)==1))
						res+=bit
					x1=int(x1/2)
					x2=int(x2/2)
					bit*=2
				}
				return res
			}
			# --- xor ---------------------------------------------------------
			function fnXor(x1,x2, res,bit) {
				res=0
				bit=1
				while (x1>0 || x2>0) {
					if ((((x1%2)==1) && ((x2%2)==0)) || (((x1%2)==0) && ((x2%2)==1)))
						res+=bit
					x1=int(x1/2)
					x2=int(x2/2)
					bit*=2
				}
				return res
			}
			# --- lshift ------------------------------------------------------
#			function fnLshift(x,n) {
#				return int(x*(2^n))
#			}
			# --- rshift ------------------------------------------------------
#			function fnRshift(x,n) {
#				return int(x/(2^n))
#			}
			# --- cidr -> netmask ---------------------------------------------
			function fnCidr2netmask(x, n){
				n=fnXor((2^32-1),(int(2^(32-x))-1))
				printf "%d.%d.%d.%d",
					fnAnd(int(n/(2^24)),255),
					fnAnd(int(n/(2^16)),255),
					fnAnd(int(n/(2^ 8)),255),
					fnAnd(    n        ,255)
			}
			# --- netmask -> cidr ---------------------------------------------
			function fnNetmask2cidr(x1,x2,x3,x4, n,c){
				n=fnXor((2^32-1),(int(x1*(2^24))+int(x2*(2^16))+int(x3*(2^8))+x4))
				c=0
				while (n>0) {
					if (n%2==1)
						c++
					n=int(n/2)
				}
				printf "%d",(32-c)
			}
			# -----------------------------------------------------------------
			{
				if (NF==1)
					fnCidr2netmask($1)
				else
					fnNetmask2cidr($1,$2,$3,$4)
			}
		'
}

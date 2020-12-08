import sys
import os

def main():
   filepath = sys.argv[1]

   qname_string = "queue name"
   qaddr_string = "address name"
   qtype_m_string = "multicast"
   qtype_a_string = "anycast"

   qlist = []
   if not os.path.isfile(filepath):
       print("File path {} does not exist. Exiting...".format(filepath))
       sys.exit()

   with open(filepath) as fp:
       cnt = 0
       for line in fp:
           if qtype_m_string in line or qtype_a_string in line:
                qtype = line[line.index('<')+1:line.rindex('>')]
           if qaddr_string in line:
                qaddr = line[line.index('"'):line.rindex('"')+1]
           if qname_string in line:
                qname = line[line.index('"'):line.rindex('"')+1]
                elem = "{\"{#QADDR}\":" + qaddr + ",\"{#QNAME}\":" + qname + ",\"{#QTYPE}\":\"" + qtype + "\"}"
                qlist.append(elem)
           cnt += 1
       print '{"data":[',
       for item in qlist[:-1]:
           print "%s," % item,
       print "%s]}" % qlist[-1]


if __name__ == '__main__':
   main()

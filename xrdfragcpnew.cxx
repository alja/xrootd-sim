//
// Get a fragment of a file and write it out to stdout.
//
// Note that one should have a valid GSI proxy, error messages from
//
//
// Example usage:
//   ./xrdfragcp --frag 0 1024 --frag 2048 1024 root://xrootd.unl.edu//store/mc/Summer12/WJetsToLNu_TuneZ2Star_8TeV-madgraph-tarball/AODSIM/PU_S7_START52_V9-v2/00000/E47B9F8B-42EF-E111-A3A4-003048FFD756.root


#include "XrdCl/XrdClFile.hh"

#include <pcrecpp.h>

#include <memory>
#include <string>
#include <list>

#include <cstdio>
#include <stdio.h>
#include <iostream>
#include <cstdlib>
#include <cstring>

#include <fcntl.h>
#include <sys/time.h>

typedef std::string      Str_t;
typedef std::list<Str_t> lStr_t;
typedef lStr_t::iterator lStr_i;

//==============================================================================

struct Frag
{
  long long fOffset;
  int       fLength;

  Frag(long long off, int len) : fOffset(off), fLength(len) {}
};

typedef std::list<Frag>   lFrag_t;
typedef lFrag_t::iterator lFrag_i;

//==============================================================================

class App
{
  lStr_t    mArgs;

  Str_t     mCmdName;
  Str_t     mPrefix;
  Str_t     mUrl;

  bool      bVerbose;

  lFrag_t   mFrags;
  int       mMaxFragLength;

  bool      bCmsClientSim;
  long long mCcsBytesToRead;
  int       mCcsNReqs;
  int       mCcsTotalTime;

  int       mNvread;

public:
  App();

  void ReadArgs(int argc, char *argv[]);
  void ParseArgs();

  void Run();


  // Various modes
  
  void GetFrags();
  void GetChecksum();
  void CmsClientSim();
};

//==============================================================================

App::App() :
  mPrefix        ("fragment"),
  bVerbose       (false),
  mMaxFragLength (0),
  bCmsClientSim  (false),
  mNvread(0)
{}

//------------------------------------------------------------------------------

void App::ReadArgs(int argc, char *argv[])
{
  mCmdName = argv[0];
  for (int i = 1; i < argc; ++i)
  {
    mArgs.push_back(argv[i]);
  }
}

void next_arg_or_die(lStr_t& args, lStr_i& i, bool allow_single_minus=false)
{
  lStr_i j = i;
  if (++j == args.end() || ((*j)[0] == '-' && ! (*j == "-" && allow_single_minus)))
  {
 std::cerr <<"Error: option "<< *i <<" requires an argument.\n";
    exit(1);
  }
  i = j;
}

void App::ParseArgs()
{
  lStr_i i = mArgs.begin();

  while (i != mArgs.end())
  {
    lStr_i start = i;

    if (*i == "-h" || *i == "-help" || *i == "--help" || *i == "-?")
    {
      printf("Arguments: [options] url\n"
             "\n"
             "  url              url of file to fetch the fragments from\n"
             "\n"
             "  --verbose        be more talkative (only for --cmsclientsim)\n"
             "\n"
             "  --prefix <str>   prefix for created fragments, full name will be like:\n"
             "                     prefix-offset-length\n"
             "                   default is 'fragment'\n"
             "                   if '[drop]' is used, nothing is written\n"
             "\n"
             "  --frag <offset> <length>\n"
             "                   get this fragment, several --frag options can be used to\n"
             "                   retrieve several fragments\n"
             "\n"
             "  --cmsclientsim <bytes-to-read> <number-of-requests> <total-time>\n"
             "                   simulate a client accessing the file with given parameters\n"
             "\n"
             "  --vread <int>    number of vreads, usedoly with cmsclientsim\n"
             );
      exit(0);
    }
    else if (*i == "--verbose")
    {
      bVerbose = true;
      mArgs.erase(start, ++i);
    }
    else if (*i == "--prefix")
    {
      next_arg_or_die(mArgs, i);
      mPrefix = *i;
      mArgs.erase(start, ++i);
    }
    else if (*i == "--frag")
    {
      next_arg_or_die(mArgs, i);
      long long offset = atoll(i->c_str());
      next_arg_or_die(mArgs, i);
      long long sizell = atoll(i->c_str());

      if (offset < 0)
      {
        fprintf(stderr, "Error: offset '%lld' must be non-negative.\n", offset);
        exit(1);
      }
      if (sizell <= 0 || sizell > 1024*1024*1024)
      {
        fprintf(stderr, "Error: size '%lld' must be larger than zero and smaller than 1GByte.\n", sizell);
        exit(1);
      }

      int size = sizell;
      mFrags.push_back(Frag(offset, size));
      if (size > mMaxFragLength) mMaxFragLength = size;

      mArgs.erase(start, ++i);
    }
    else if (*i == "--cmsclientsim")
    {
      next_arg_or_die(mArgs, i);
      mCcsBytesToRead = atoll(i->c_str());
      if (mCcsBytesToRead < 0)
      {
        fprintf(stderr, "Error: bytes-to-read '%lld' must be non-negative.\n", mCcsBytesToRead);
        exit(1);
      }

      next_arg_or_die(mArgs, i);
      mCcsNReqs = atoi(i->c_str());
      if (mCcsNReqs < 0)
      {
        fprintf(stderr, "Error: number-of-requests '%lld' must be non-negative.\n", mCcsNReqs);
        exit(1);
      }

      next_arg_or_die(mArgs, i);
      mCcsTotalTime = atoi(i->c_str());
      if (mCcsTotalTime < 0)
      {
        fprintf(stderr, "Error: total-time '%lld' must be non-negative.\n", mCcsTotalTime);
        exit(1);
      }

      bCmsClientSim = true;

      mArgs.erase(start, ++i);
    }
    else if (*i == "--vread")
    {
      next_arg_or_die(mArgs, i);
      mNvread = atoi(i->c_str());
      printf("ReadV enabled. Split reads into %d chunks.\n", mNvread);

      mArgs.erase(start, ++i);
    }
    else
    {
      ++i;
    }
  }

  if (mFrags.empty() && ! bCmsClientSim)
  {
    fprintf(stderr, "Error: at least one fragment should be requested.\n");
    exit(1);
  }

  if (mArgs.size() != 1)
  {
    fprintf(stderr, "Error: exactly one file should be requested, %d arguments found.\n", (int) mArgs.size());
    exit(1);
  }

  mUrl = mArgs.front();
}

//==============================================================================

void App::Run()
{
  if (bCmsClientSim)
  {
    CmsClientSim();
  }
  else
  {
    GetFrags();
  }
}

//==============================================================================

void App::GetFrags()
{/*
  std::auto_ptr<XrdClient> c( new XrdClient(mUrl.c_str()) );

  if ( ! c->Open(0, kXR_async) || c->LastServerResp()->status != kXR_ok)
  {
    fprintf(stderr, "Error opening file '%s'.\n", mUrl.c_str());
    exit(1);
  }

  XrdClientStatInfo si;
  c->Stat(&si);

  for (lFrag_i i = mFrags.begin(); i != mFrags.end(); ++i)
  {
    if (i->fOffset + i->fLength > si.size)
    {
      fprintf(stderr, "Error: requested chunk not in file, file-size=%lld.\n", si.size);
      exit(1);
    }
  }

  std::vector<char> buf;
  buf.reserve(mMaxFragLength);

  int fnlen = mPrefix.length() + 32;
  std::vector<char> fn;
  fn.reserve(fnlen);

  for (lFrag_i i = mFrags.begin(); i != mFrags.end(); ++i)
  {
    int n = snprintf(&fn[0], fnlen, "%s-%lld-%d", mPrefix.c_str(), i->fOffset, i->fLength);
    if (n >= fnlen)
    {
      fprintf(stderr, "Internal error: file-name buffer too small.\n");
      exit(1);
    }

    int fd = open(&fn[0], O_WRONLY | O_CREAT | O_TRUNC,
                          S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
    if (fd == -1)
    {
      fprintf(stderr, "Error opening output file '%s': %s\n", &fn[0], strerror(errno));
      exit(1);
    }

    c->Read(&buf[0], i->fOffset, i->fLength);

    write(fd, &buf[0], i->fLength);

    close(fd);
    }*/


    printf( "AMT no imeple,\n");
}

//------------------------------------------------------------------------------

void App::GetChecksum()
{

    printf( "AMT no imeple,\n");
}

//------------------------------------------------------------------------------

void App::CmsClientSim()
{
    using namespace XrdCl;

    File * clFile = new XrdCl::File();
    OpenFlags::Flags XOflags =  XrdCl::OpenFlags::Read;
    XRootDStatus Status =  clFile->Open(mUrl, XOflags);
    if (Status.IsOK() == false) {
       printf("Error opennig file %s\n", mUrl.c_str());
    }

    XrdCl::StatInfo *sInfo = 0;
    XRootDStatus StatusS = clFile->Stat(true, sInfo);
    if (!Status.IsOK()) {
       printf("Can't get status for %s \n", mUrl.c_str());
       exit(1);
    }


    long long request_size = mCcsBytesToRead / mCcsNReqs;
    if (request_size > 128*1024*1024)
    {
        fprintf(stderr, "Error: request size (%lld) larger than 128MB.\n", request_size);
        exit(1);
    }
    if (request_size <= 0)
    {
        fprintf(stderr, "Error: request size (%lld) non-positive.\n", request_size);
        exit(1);
    }
    if (request_size > sInfo->GetSize())
    {
        fprintf(stderr, "Error: request size (%lld) larger than file size (%lld).\n", request_size, sInfo->GetSize());
        exit(1);
    }

    long long usleep_time = 1000000 * ((double)mCcsTotalTime / mCcsNReqs);
    if (usleep_time < 0)
    {
        fprintf(stderr, "Error: sleeptime (%lldmus) negative.\n", usleep_time);
        exit(1);
    }

    std::vector<char> buf;
    buf.reserve(request_size);

    long long offset = 0;
    long long toread = mCcsBytesToRead;

    int* vecReq = 0;
    kXR_int64* vecOff = 0;
    if (mNvread) {
        vecReq = new int[mNvread];
        vecOff = new kXR_int64[mNvread];
    }

    // if (bVerbose)
    {
        printf("Starting CmsClientSimNew, %f MB to read in about %lld requests spaced by %.1f seconds.\n",
               toread/1024.0/1024.0, mCcsNReqs, usleep_time/1000000.0);
    }

    int count = 0;

    while (toread > 0)
    {
        timeval beg, end;
        gettimeofday(&beg, 0);

        long long req = (toread >= request_size) ? request_size : toread;

        if (offset + req > sInfo->GetSize())
        {
            offset = 0;
        }

        ++count;
        if (bVerbose)
        {
            printf("%3d Reading %.3f MB at offset %lld\n", count, req/1024.0/1024.0, offset);
        }


        // AMT
        if (mNvread) {
            /*
            XrdCl::XRootDStatus StatusV;
            XrdCl::ChunkList chunkVec;
            XrdCl::VectorReadInfo *vrInfo;
            int i, nbytes = 0;

            // Copy in the vector (would be nice if we didn't need to do this)
            //
            chunkVec.reserve(mNvread);
            for (i = 0; i < mNvread; i++)
            {
                nbytes += readV[i].size;
                chunkVec.push_back(XrdCl::ChunkInfo(offset + vreq*v,
                                                    vreq,
                                                    &buf[0]
                                                    ));
            }
            */


            //            if (bVerbose) printf(" vector read  from new client PLEASE DOUBLE CHECK,  %d x %d \n",mNvread,  vreq);
            //StatusV = clFile->VectorRead(chunkVec, (void *)0, vrInfo);
        }
        else
        {
            int res = 0;
            uint32_t bytes;
            clFile->Read( offset, (int)req,&buf[0], bytes);
            req = bytes;
        }

        offset += req;
        toread -= req;

        gettimeofday(&end, 0);

        long long sleepy = usleep_time - (1000000ll*(end.tv_sec - beg.tv_sec) + (end.tv_usec - beg.tv_usec));
        if (sleepy > 0)
        {
            if (bVerbose)
            {
                printf("    Sleeping for %.1f seconds.\n", sleepy/1000000.0);
            }
            usleep(usleep_time);
        }
        else
        {
            if (bVerbose)
            {
                printf("    Not sleeping ... was already %.1f seconds too late.\n", -sleepy/1000000.0);
            }
        }
    }
}

//==============================================================================
#include "XrdVersion.hh"

int main(int argc, char *argv[])
{
  std::cerr << "Xrootd Version === " XrdVERSION  << std::endl;
if (!strncmp(XrdVERSION, "v3",2 )) {
printf("inproper version \n");
exit(1);
} 

  App app;

  app.ReadArgs(argc, argv);
  app.ParseArgs();

  // Testing of check-sum retrieval ... works not.
  // app.GetChecksum();
  // return 0;

  app.Run();

  return 0;
}
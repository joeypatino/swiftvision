#ifndef PtraArray_hpp
#define PtraArray_hpp

struct PtrArray
{
    int          nalloc;    /*!< size of allocated ptr array         */
    int          imax;      /*!< greatest valid index                */
    int          nactual;   /*!< actual number of stored elements    */
    void         **array;   /*!< ptr array                           */
};
typedef struct PtrArray  PtrArray;

/*------------------------------------------------------------------------*
 *                              Array flags                               *
 *------------------------------------------------------------------------*/

/*! Flags for removal from PtraArray */
enum {
    L_NO_COMPACTION = 1,        /*!< null the pointer only                */
    L_COMPACTION = 2            /*!< compact the array                    */
};

/*! Flags for insertion into PtraArray */
enum {
    L_AUTO_DOWNSHIFT = 0,     /*!< choose based on number of holes        */
    L_MIN_DOWNSHIFT = 1,      /*!< downshifts min # of ptrs below insert  */
    L_FULL_DOWNSHIFT = 2      /*!< downshifts all ptrs below insert       */
};

namespace dewarp {
    PtrArray * ptraCreate(int n);
    void ptraDestroy(PtrArray **ppa,
                     int freeflag,
                     int warnflag);
    int ptraGetActualCount(PtrArray *pa,
                           int *pcount);
    void *ptraGetPtrToItem(PtrArray *pa,
                           int index);
    int ptraGetMaxIndex(PtrArray *pa,
                        int *pmaxindex);
    void *ptraRemove(PtrArray *pa,
                     int index,
                     int flag);
    void *ptraRemoveLast(PtrArray *pa);
    int ptraInsert(PtrArray  *pa,
                   int index,
                   void *item,
                   int shiftflag);
}

#endif /* PtraArray_hpp */

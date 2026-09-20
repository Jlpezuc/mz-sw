#include "mz_PushButton_facade.h"

static mz_PushButton PBEnableSystem;
static mz_PushButton PBEnableControl;
static mz_PushButton PBStop;

void mz_PushButton_facade_init(mz_PushButtonFacadeCfg cfg)
{
	mz_PushBotton_init(&PBEnableSystem, (cfg.EnableSystem));
	mz_PushBotton_init(&PBEnableControl, (cfg.EnableControl));
	mz_PushBotton_init(&PBStop, (cfg.Stop));
}

_Bool mz_GetPushButtonStop()
{
	return (mz_PushButton_GetValue(&PBStop));
}

_Bool mz_GetPushButtonEnableSystem()
{
	return (mz_PushButton_GetValue(&PBEnableSystem));
}

_Bool mz_GetPushButtonEnableControl()
{
	return mz_PushButton_GetValue(&PBEnableControl);
}

#include <jni.h>
#include <android/sensor.h>
#include <android/log.h>
#include <pthread.h>
#include <unistd.h>

#define LOG_TAG "AccelerometerJNI"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

        ASensorManager* sensorManager = nullptr;
const ASensor* accelerometer = nullptr;
ASensorEventQueue* eventQueue = nullptr;
JavaVM* javaVM = nullptr;
jobject javaObject = nullptr;
pthread_t sensorThread = 0;
bool running = false;

void processAccelerometerEvent(ASensorEvent* event) {
    if (event->type != ASENSOR_TYPE_ACCELEROMETER) return;

    float x = event->acceleration.x;
    float y = event->acceleration.y;
    float z = event->acceleration.z;

    LOGI("Thread ID: %d, X: %.2f, Y: %.2f, Z: %.2f", gettid(), x, y, z);

    if (javaVM && javaObject) {
        JNIEnv* env = nullptr;
        bool attached = false;

        if (javaVM->GetEnv((void**)&env, JNI_VERSION_1_6) == JNI_EDETACHED) {
            if (javaVM->AttachCurrentThread(&env, nullptr) != JNI_OK) {
                LOGE("Failed to attach thread");
                return;
            }
            attached = true;
        }

        jclass cls = env->GetObjectClass(javaObject);
        if (!cls) {
            LOGE("Failed to get object class");
            if (attached) javaVM->DetachCurrentThread();
            return;
        }

        jmethodID methodId = env->GetMethodID(cls, "onAccelerometerData", "(FFF)V");
        if (methodId) {
            env->CallVoidMethod(javaObject, methodId, x, y, z);
        } else {
            LOGE("Method onAccelerometerData not found");
        }

        if (attached) {
            javaVM->DetachCurrentThread();
        }
    }
}

void* sensorThreadFunc(void*) {
    LOGI("Sensor thread started, Thread ID: %d", gettid());

    // Создаём Looper только для фонового потока
    ALooper* looper = ALooper_prepare(ALOOPER_PREPARE_ALLOW_NON_CALLBACKS);
    if (!looper) {
        LOGE("Failed to prepare looper");
        return nullptr;
    }

    while (running) {
        ASensorEvent event;
        while (running && ASensorEventQueue_getEvents(eventQueue, &event, 1) > 0) {
            processAccelerometerEvent(&event);
        }
        usleep(100000); // Ожидание 100 мс
    }

    LOGI("Sensor thread stopped");
    return nullptr;
}

extern "C" JNIEXPORT void JNICALL
Java_com_example_dishes_1app_AccelerometerJNI_startAccelerometer(JNIEnv* env, jobject instance) {
LOGI("Starting accelerometer");

if (running) {
LOGI("Accelerometer already running");
return;
}

env->GetJavaVM(&javaVM);
javaObject = env->NewGlobalRef(instance);

sensorManager = ASensorManager_getInstance();
if (!sensorManager) {
LOGE("Failed to get sensor manager");
return;
}

accelerometer = ASensorManager_getDefaultSensor(sensorManager, ASENSOR_TYPE_ACCELEROMETER);
if (!accelerometer) {
LOGE("Failed to get accelerometer sensor");
return;
}

// Используем looper из фонового потока, поэтому здесь не создаём
eventQueue = ASensorManager_createEventQueue(sensorManager, ALooper_forThread(), 0, nullptr, nullptr);
if (!eventQueue) {
LOGE("Failed to create event queue");
return;
}

if (ASensorEventQueue_enableSensor(eventQueue, accelerometer) < 0) {
LOGE("Failed to enable sensor");
return;
}

if (ASensorEventQueue_setEventRate(eventQueue, accelerometer, 100000) < 0) { // 10 Гц
LOGE("Failed to set event rate");
return;
}

running = true;
if (pthread_create(&sensorThread, nullptr, sensorThreadFunc, nullptr) != 0) {
LOGE("Failed to create sensor thread");
running = false;
return;
}
}

extern "C" JNIEXPORT void JNICALL
Java_com_example_dishes_1app_AccelerometerJNI_stopAccelerometer(JNIEnv* env, jobject instance) {
LOGI("Stopping accelerometer");

running = false;

if (sensorThread) {
pthread_join(sensorThread, nullptr);
sensorThread = 0;
}

if (eventQueue && accelerometer) {
ASensorEventQueue_disableSensor(eventQueue, accelerometer);
}

if (eventQueue) {
ASensorManager_destroyEventQueue(sensorManager, eventQueue);
eventQueue = nullptr;
}

if (javaObject) {
env->DeleteGlobalRef(javaObject);
javaObject = nullptr;
}

accelerometer = nullptr;
sensorManager = nullptr;
}

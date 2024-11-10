package com.niwiart.flutter_bluetooth_printer_demo.thermalPrinterX

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothServerSocket
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.content.pm.PackageManager
import android.os.Bundle
import android.os.Handler
import android.util.Log
import androidx.core.app.ActivityCompat
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.util.*

class BluetoothChatService {

    // Member fields
    private var mAdapter: BluetoothAdapter? = null
    private var mHandler: Handler? = null
    private var mSecureAcceptThread: AcceptThread? = null
    private var mInsecureAcceptThread: AcceptThread? = null
    private var mConnectThread: ConnectThread? = null
    private var mConnectedThread: ConnectedThread? = null
    private var mState = 0
    private var mContext: Context;

    /**
     * Constructor. Prepares a new BluetoothChat session.
     * @param context  The UI Activity Context
     * @param handler  A Handler to send messages back to the UI Activity
     */
    constructor(context: Context, handler: Handler?) {
        val btManager = context.getSystemService(Activity.BLUETOOTH_SERVICE) as BluetoothManager
        mAdapter = btManager.adapter
        mState = STATE_NONE
        mHandler = handler
        mContext = context
    }

    /**
     * Set the current state of the chat connection
     * @param state  An integer defining the current connection state
     */
    @Synchronized
    private fun setState(state: Int) {
        if (D) Log.d(TAG, "setState() $mState -> $state")
        mState = state

        // Give the new state to the Handler so the UI Activity can update
        mHandler!!.obtainMessage(Const.MESSAGE_BLUETOOTH_STATE_CHANGE, state, -1).sendToTarget()
    }

    /**
     * Return the current connection state.  */
    @Synchronized
    fun getState(): Int {
        return mState
    }

//    /**
//     * Start the chat service. Specifically start AcceptThread to begin a
//     * session in listening (server) mode. Called by the Activity onResume()  */
//    @Synchronized
//    fun start() {
//        if (D) Log.d(TAG, "start")
//
//        // Cancel any thread attempting to make a connection
//        if (mConnectThread != null) {
//            mConnectThread!!.cancel()
//            mConnectThread = null
//        }
//
//        // Cancel any thread currently running a connection
//        if (mConnectedThread != null) {
//            mConnectedThread!!.cancel()
//            mConnectedThread = null
//        }
//        setState(STATE_LISTEN)
//
//        // Start the thread to listen on a BluetoothServerSocket
//        if (mSecureAcceptThread == null) {
//            mSecureAcceptThread = AcceptThread(true)
//            mSecureAcceptThread!!.start()
//        }
//        if (mInsecureAcceptThread == null) {
//            mInsecureAcceptThread = AcceptThread(false)
//            mInsecureAcceptThread!!.start()
//        }
//    }

    /**
     * Start the ConnectThread to initiate a connection to a remote device.
     * @param device  The BluetoothDevice to connect
     * @param secure Socket Security type - Secure (true) , Insecure (false)
     */
    @Synchronized
    fun connect(device: BluetoothDevice, secure: Boolean) {
        if (D) Log.d(TAG, "connect to: $device")

        // Cancel any thread attempting to make a connection
        if (mState == STATE_CONNECTING) {
            if (mConnectThread != null) {
                mConnectThread!!.cancel()
                mConnectThread = null
            }
        }

        // Cancel any thread currently running a connection
        if (mConnectedThread != null) {
            mConnectedThread!!.cancel()
            mConnectedThread = null
        }

        // Start the thread to connect with the given device
        mConnectThread = ConnectThread(device, secure)
        mConnectThread!!.start()
        setState(STATE_CONNECTING)
    }

    /**
     * Start the ConnectedThread to begin managing a Bluetooth connection
     * @param socket  The BluetoothSocket on which the connection was made
     * @param device  The BluetoothDevice that has been connected
     */
    @SuppressLint("MissingPermission")
    @Synchronized
    fun connected(socket: BluetoothSocket, device: BluetoothDevice, socketType: String) {
        if (D) Log.d(TAG, "connected, Socket Type:$socketType")

        // Cancel the thread that completed the connection
        if (mConnectThread != null) {
            mConnectThread!!.cancel()
            mConnectThread = null
        }

        // Cancel any thread currently running a connection
        if (mConnectedThread != null) {
            mConnectedThread!!.cancel()
            mConnectedThread = null
        }

        // Cancel the accept thread because we only want to connect to one device
        if (mSecureAcceptThread != null) {
            mSecureAcceptThread!!.cancel()
            mSecureAcceptThread = null
        }
        if (mInsecureAcceptThread != null) {
            mInsecureAcceptThread!!.cancel()
            mInsecureAcceptThread = null
        }

        // Start the thread to manage the connection and perform transmissions
        mConnectedThread = ConnectedThread(socket, socketType)
        mConnectedThread!!.start()

        // Send the name of the connected device back to the UI Activity
        val msg = mHandler!!.obtainMessage(Const.MESSAGE_BLUETOOTH_DEVICE_NAME)
        val bundle = Bundle()
        bundle.putString(Const.DEVICE_NAME, device.name)
        msg.data = bundle
        mHandler!!.sendMessage(msg)
        setState(STATE_CONNECTED)
    }

    /**
     * Stop all threads
     */
    @Synchronized
    fun stop() {
        if (D) Log.d(TAG, "stop")
        if (mConnectThread != null) {
            mConnectThread!!.cancel()
            mConnectThread = null
        }
        if (mConnectedThread != null) {
            mConnectedThread!!.cancel()
            mConnectedThread = null
        }
        if (mSecureAcceptThread != null) {
            mSecureAcceptThread!!.cancel()
            mSecureAcceptThread = null
        }
        if (mInsecureAcceptThread != null) {
            mInsecureAcceptThread!!.cancel()
            mInsecureAcceptThread = null
        }
        setState(STATE_NONE)
    }

    /**
     * Write to the ConnectedThread in an unsynchronized manner
     * @param out The bytes to write
     * @see ConnectedThread.write
     */
    fun write(out: ByteArray?) {
        // Create temporary object
        var r: ConnectedThread?
        // Synchronize a copy of the ConnectedThread
        synchronized(this) {
            if (mState != STATE_CONNECTED) return
            r = mConnectedThread
        }
        // Perform the write unsynchronized
        r!!.write(out)
    }

    /**
     * Indicate that the connection attempt failed and notify the UI Activity.
     */
    private fun connectionFailed() {
        // Send a failure message back to the Activity
        val msg = mHandler!!.obtainMessage(Const.MESSAGE_BLUETOOTH_TOAST)
        val bundle = Bundle()
        bundle.putString(Const.TOAST, "Unable to connect device")
        msg.data = bundle
        mHandler!!.sendMessage(msg)
        mHandler!!.obtainMessage(Const.MESSAGE_BLUETOOTH_CONNECT_FAIL).sendToTarget()
//        // Start the service over to restart listening mode
//        start()
    }

    /**
     * Indicate that the connection was lost and notify the UI Activity.
     */
    private fun connectionLost() {
        // Send a failure message back to the Activity
        val msg = mHandler!!.obtainMessage(Const.MESSAGE_BLUETOOTH_TOAST)
        val bundle = Bundle()
        bundle.putString(Const.TOAST, "Device connection was lost")
        msg.data = bundle
        mHandler!!.sendMessage(msg)

//        // Start the service over to restart listening mode
//        start()
    }

    /**
     * This thread runs while listening for incoming connections. It behaves
     * like a server-side client. It runs until a connection is accepted
     * (or until cancelled).
     */
    private inner class AcceptThread @SuppressLint("NewApi") constructor(secure: Boolean) :
        Thread() {
        // The local server socket
        private val mmServerSocket: BluetoothServerSocket?
        private val mSocketType: String

        init {
            var tmp: BluetoothServerSocket? = null
            mSocketType = if (secure) "Secure" else "Insecure"

            // Create a new listening server socket
            try {
                if (ActivityCompat.checkSelfPermission(
                        mContext,
                        Manifest.permission.BLUETOOTH_CONNECT
                    ) == PackageManager.PERMISSION_GRANTED
                ) {
//                    tmp = if (secure) {
//                        mAdapter!!.listenUsingRfcommWithServiceRecord(
//                            NAME_SECURE,
//                            MY_UUID_SPP
//                        )
//                    } else {
//                        mAdapter!!.listenUsingInsecureRfcommWithServiceRecord(
//                            NAME_INSECURE, MY_UUID_INSECURE
//                        )
//                    }
                    tmp = mAdapter!!.listenUsingRfcommWithServiceRecord(
                            NAME_SECURE,
                            MY_UUID_SPP
                        )
                } else {
                    tmp = null;
                }
            } catch (e: IOException) {
                Log.e(TAG, "Socket Type: " + mSocketType + "listen() failed", e)
            }
            mmServerSocket = tmp
        }

        override fun run() {
            if (D) Log.d(
                TAG, "Socket Type: " + mSocketType +
                        "BEGIN mAcceptThread" + this
            )
            name = "AcceptThread$mSocketType"
            var socket: BluetoothSocket?

            // Listen to the server socket if we're not connected
            while (mState != STATE_CONNECTED) {
                socket = try {
                    // This is a blocking call and will only return on a
                    // successful connection or an exception
                    mmServerSocket!!.accept()
                } catch (e: IOException) {
                    Log.e(TAG, "Socket Type: " + mSocketType + "accept() failed", e)
                    break
                }

                // If a connection was accepted
                if (socket != null) {
                    synchronized(this@BluetoothChatService) {
                        when (mState) {
                            STATE_LISTEN, STATE_CONNECTING ->                             // Situation normal. Start the connected thread.
                                connected(
                                    socket, socket.remoteDevice,
                                    mSocketType
                                )
                            STATE_NONE, STATE_CONNECTED ->                             // Either not ready or already connected. Terminate new socket.
                                try {
                                    socket.close()
                                } catch (e: IOException) {
                                    Log.e(TAG, "Could not close unwanted socket", e)
                                }
                            else -> {

                            }
                        }
                    }
                }
            }
            if (D) Log.i(TAG, "END mAcceptThread, socket Type: $mSocketType")
        }

        fun cancel() {
            if (D) Log.d(TAG, "Socket Type" + mSocketType + "cancel " + this)
            try {
                mmServerSocket!!.close()
            } catch (e: IOException) {
                Log.e(TAG, "Socket Type" + mSocketType + "close() of server failed", e)
            }
        }
    }


    /**
     * This thread runs while attempting to make an outgoing connection
     * with a device. It runs straight through; the connection either
     * succeeds or fails.
     */
    private inner class ConnectThread @SuppressLint("NewApi") constructor(
        private val mmDevice: BluetoothDevice,
        secure: Boolean
    ) :
        Thread() {
        private val mmSocket: BluetoothSocket?
        private val mSocketType: String

        init {
            var tmp: BluetoothSocket? = null
            mSocketType = if (secure) "Secure" else "Insecure"

            // Get a BluetoothSocket for a connection with the
            // given BluetoothDevice
            try {
                if(ActivityCompat.checkSelfPermission(
                        mContext,
                        Manifest.permission.BLUETOOTH_CONNECT
                    ) == PackageManager.PERMISSION_GRANTED){
//                    tmp = if (secure) {
//                        mmDevice.createRfcommSocketToServiceRecord(
//                            MY_UUID_SPP
//                        )
//                    } else {
//                        mmDevice.createInsecureRfcommSocketToServiceRecord(
//                            MY_UUID_INSECURE
//                        )
//                    }
                    tmp = mmDevice.createRfcommSocketToServiceRecord(
                            MY_UUID_SPP
                        )
                } else {
                    tmp = null;

                }

            } catch (e: IOException) {
                Log.e(TAG, "Socket Type: " + mSocketType + "create() failed", e)
            }
            mmSocket = tmp
        }

        override fun run() {
            Log.i(TAG, "BEGIN mConnectThread SocketType:$mSocketType")
            name = "ConnectThread$mSocketType"

            // Always cancel discovery because it will slow down a connection
            mAdapter!!.cancelDiscovery()

            // Make a connection to the BluetoothSocket
            try {
                // This is a blocking call and will only return on a
                // successful connection or an exception
                mmSocket!!.connect()
            } catch (e: IOException) {
                Log.e(DEBUG_TAG, "Error Connect socket $e")
                // Close the socket
                try {
                    mmSocket!!.close()
                } catch (e2: IOException) {
                    Log.e(
                        TAG, "unable to close() " + mSocketType +
                                " socket during connection failure", e2
                    )
                }
                connectionFailed()
                return
            }

            // Reset the ConnectThread because we're done
            synchronized(this@BluetoothChatService) { mConnectThread = null }

            // Start the connected thread
            connected(mmSocket, mmDevice, mSocketType)
        }

        fun cancel() {
            try {
                mmSocket!!.close()
            } catch (e: IOException) {
                Log.e(TAG, "close() of connect $mSocketType socket failed", e)
            }
        }
    }

    /**
     * This thread runs during a connection with a remote device.
     * It handles all incoming and outgoing transmissions.
     */
    private inner class ConnectedThread(socket: BluetoothSocket, socketType: String) :
        Thread() {
        private val mmSocket: BluetoothSocket
        private val mmInStream: InputStream?
        private val mmOutStream: OutputStream?

        init {
            Log.d(TAG, "create ConnectedThread: $socketType")
            mmSocket = socket
            var tmpIn: InputStream? = null
            var tmpOut: OutputStream? = null

            // Get the BluetoothSocket input and output streams
            try {
                tmpIn = socket.inputStream
                tmpOut = socket.outputStream
            } catch (e: IOException) {
                Log.e(TAG, "temp sockets not created", e)
            }
            mmInStream = tmpIn
            mmOutStream = tmpOut
        }

        override fun run() {
            Log.i(TAG, "BEGIN mConnectedThread")
            //            byte[] buffer = new byte[1024];
            var bytes: Int
            try {
                sleep(100)
            } catch (e1: InterruptedException) {
                // TODO Auto-generated catch block
                e1.printStackTrace()
            }
            while (mState == STATE_CONNECTED) {
                try {
                    val buffer = ByteArray(256)
                    bytes = mmInStream!!.read(buffer)
                    //mDataParse.Add(buffer, bytes);
                    if (bytes > 0) {
                        val dat = ByteArray(bytes)
                        System.arraycopy(buffer, 0, dat, 0, bytes)
                        //Log.d("USB_SERIAL", "Read " + numBytesRead + " bytes.");
                        mHandler!!.obtainMessage(Const.MESSAGE_BLUETOOTH_DATA, dat).sendToTarget()
                    }
                } catch (e: IOException) {
                    Log.e(TAG, "disconnected", e)
                    connectionLost()
//                    // Start the service over to restart listening mode
//                    this@BluetoothChatService.start()
                    break
                }
                try {
                    sleep(40)
                } catch (e: InterruptedException) {
                    // TODO Auto-generated catch block
                    e.printStackTrace()
                }
            }
        }

        /**
         * Write to the connected OutStream.
         * @param buffer  The bytes to write
         */
        fun write(buffer: ByteArray?) {
            try {
                mmOutStream!!.write(buffer)

                // Share the sent message back to the UI Activity
                mHandler!!.obtainMessage(Const.MESSAGE_BLUETOOTH_WRITE, -1, -1, buffer)
                    .sendToTarget()
            } catch (e: IOException) {
                Log.e(TAG, "Exception during write", e)
            }
        }

        fun cancel() {
            try {
                mmSocket.close()
            } catch (e: IOException) {
                Log.e(TAG, "close() of connect socket failed", e)
            }
        }
    }

    companion object {
        // Constants that indicate the current connection state
        const val STATE_NONE = 0 // we're doing nothing

        const val STATE_LISTEN = 1 // now listening for incoming connections

        const val STATE_CONNECTING = 2 // now initiating an outgoing connection

        const val STATE_CONNECTED = 3 // now connected to a remote device

        // Debugging
        private const val TAG = "BluetoothChatService"
        private const val D = true

        // Name for the SDP record when creating server socket
        private const val NAME_SECURE = "BluetoothChatSecure"
        private const val NAME_INSECURE = "BluetoothChatInsecure"

        // Unique UUID for this application
//        private val MY_UUID_INSECURE = UUID.fromString("8ce255c0-200a-11e0-ac64-0800200c9a66")

        //��������������ͨ�õ�UUID����Ҫ���
        private val MY_UUID_SPP = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

        private const val DEBUG_TAG : String = "BluetoothChatService";

    }
}